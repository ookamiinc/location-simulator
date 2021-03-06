require 'json'
require 'firebase'
require 'byebug'

FIREBASE_BASE_URI = 'https://yourprojectid.firebaseio.com/'.freeze
FIREBASE_PRIVATE_KEY_JSON = 'firebase-adminsdk.json'.freeze

GEOJSON_FILE = 'okayama.geojson'.freeze

COMPETITION_ID = 1
CAR_ID = 1

OKAYAMA_CARS = [15, 20, 21, 24, 25, 31, 36, 51, 60, 77, 98]
SUGO_CARS = [15, 20, 21, 24, 25, 31, 36, 60, 77, 98]

def simulate(car_id, number_of_same_location = 1, delay = 0, use_same_time_for_same_location = true)
  last_lat = nil
  last_long = nil
  d = 0

  coordinates_from_geojson.each do |coordinate|
    longitude = coordinate[0]
    latitude = coordinate[1]

    if last_lat && last_long
      d = distance([last_lat, last_long], [latitude, longitude])
    end
    sleep(rand(0.6..0.9) + [0, 1].sample * delay)
    timestamp = Time.now.to_f
    number_of_same_location.times do |_i|
      timestamp = Time.now.to_f unless use_same_time_for_same_location
      firebase.push("v1/locations/#{COMPETITION_ID}/#{car_id}", {
        latitude: latitude,
        longitude: longitude,
        speed: d,
        timestamp: timestamp,
        course: -1
      })
    end

    last_lat = latitude
    last_long = longitude
  end
end

def simulate_25_cars
  threads = []
  threads << Thread.new { simulate(1) }
  (2..25).each do |i|
    threads << Thread.fork { simulate(i) }
  end
  threads.each { |t| t.join }
end

def simulate_okayama_cars
  threads = []
  OKAYAMA_CARS.each do |i|
    threads << Thread.new { simulate(i) }
  end
  threads.each { |t| t.join }
end

def simulate_okayama_cars_with_delay
  threads = []
  OKAYAMA_CARS.each do |i|
    threads << Thread.new { simulate(i, 1, i * 0.01) }
  end
  threads.each { |t| t.join }
end

def simulate_okayama_cars_with_same_location_on_same_time
  threads = []
  OKAYAMA_CARS.each do |i|
    threads << Thread.new { simulate(i, 3, i * 0.01) }
  end
  threads.each { |t| t.join }
end

def simulate_okayama_cars_with_same_location_on_different_time
  threads = []
  OKAYAMA_CARS.each do |i|
    threads << Thread.new { simulate(i, 3, i * 0.01, false) }
  end
  threads.each { |t| t.join }
end

def simulate_fuji(car_id)
  file = File.open("fuji-#{car_id}.json")
  hash = JSON.parse(file.read)
  hash.each do |v|
    sleep(rand(1.0..1.5))
    firebase.push("v1/locations/#{COMPETITION_ID}/#{car_id}", {
      latitude: v['latitude'],
      longitude: v['longitude'],
      speed: v['speed'],
      timestamp: Time.now.to_f,
      course: v['course']
    })
  end
end

def simulate_fuji_5_cars
  threads = []
  threads << Thread.new { simulate_fuji(3) }
  threads << Thread.fork { simulate_fuji(20) }
  threads << Thread.fork { simulate_fuji(23) }
  threads << Thread.fork { simulate_fuji(24) }
  threads << Thread.fork { simulate_fuji(25) }
  threads.each { |t| t.join }
end

def simulate_okayama_json_with_key(car_id)
  file = File.open("okayama/#{car_id}.json")
  hash = JSON.parse(file.read)
  hash.to_a.each_slice(3) do |a|
    sleep(0.5)
    timestamp = Time.now.to_f
    a.to_h.each do |_k, v|
      firebase.push("v1/locations/#{COMPETITION_ID}/#{car_id}", {
        latitude: v['latitude'],
        longitude: v['longitude'],
        speed: v['speed'],
        timestamp: timestamp,
        course: v['course']
      })
    end
  end
end

def simulate_okayama(car_id)
  file = File.open("okayama-unique-by-timestamp/#{car_id}.json")
  hash = JSON.parse(file.read)
  previous_timestamp = nil
  hash.each do |v|
    sec = previous_timestamp == nil ? 0.5 : v['timestamp'] - previous_timestamp
    sleep(sec)
    timestamp = Time.now.to_f
    1.times do |_i|
      firebase.push("v1/locations/#{COMPETITION_ID}/#{car_id}", {
        latitude: v['latitude'],
        longitude: v['longitude'],
        speed: v['speed'],
        timestamp: timestamp,
        course: v['course']
      })
    end
    previous_timestamp = v['timestamp']
  end
end

def simulate_sugo(car_id)
  file = File.open("sugo-unique-by-timestamp/#{car_id}.json")
  hash = JSON.parse(file.read)
  hash.each do |v|
    sleep(0.5)
    timestamp = Time.now.to_f
    1.times do |_i|
      firebase.push("v1/locations/#{COMPETITION_ID}/#{car_id}", {
        latitude: v['latitude'],
        longitude: v['longitude'],
        speed: v['speed'],
        timestamp: timestamp,
        course: v['course']
      })
    end
  end
end

def simulate_okayama_11_cars
  threads = []
  OKAYAMA_CARS.each do |i|
    threads << Thread.new { simulate_okayama(i) }
  end
  threads.each { |t| t.join }
end

def simulate_sugo_10_cars
  threads = []
  SUGO_CARS.each do |i|
    threads << Thread.new { simulate_sugo(i) }
  end
  threads.each { |t| t.join }
end

def coordinates_from_geojson
  file = File.open(GEOJSON_FILE)
  hash = JSON.parse(file.read)
  hash['features'].first['geometry']['coordinates']
end

def distance(loc1, loc2)
  rad_per_deg = Math::PI / 180 # PI / 180
  rkm = 6371                  # Earth radius in kilometers
  rm = rkm * 1000             # Radius in meters

  dlat_rad = (loc2[0] - loc1[0]) * rad_per_deg # Delta, converted to rad
  dlon_rad = (loc2[1] - loc1[1]) * rad_per_deg

  lat1_rad, _lon1_rad = loc1.map { |i| i * rad_per_deg }
  lat2_rad, _lon2_rad = loc2.map { |i| i * rad_per_deg }

  a = Math.sin(dlat_rad / 2)**2 + Math.cos(lat1_rad) * Math.cos(lat2_rad) * Math.sin(dlon_rad / 2)**2
  c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a))

  rm * c # Delta in meters
end

def firebase
  @firebase ||= Firebase::Client.new(FIREBASE_BASE_URI, File.open(FIREBASE_PRIVATE_KEY_JSON).read)
end

# simulate_okayama_cars
# simulate_okayama_cars_with_delay
# simulate_okayama_cars_with_same_location_on_same_time
# simulate_okayama_cars_with_same_location_on_different_time
# simulate_okayama_11_cars
simulate_sugo_10_cars
