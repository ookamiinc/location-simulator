require 'json'
require 'firebase'
require 'byebug'

FIREBASE_BASE_URI = 'https://yourprojectid.firebaseio.com/'.freeze
FIREBASE_PRIVATE_KEY_JSON = 'firebase-adminsdk.json'.freeze

GEOJSON_FILE = 'okayama.geojson'.freeze

COMPETITION_ID = 1
CAR_ID = 1

def simulate
  last_lat = nil
  last_long = nil
  d = 0

  coordinates_from_geojson.each do |coordinate|
    longitude = coordinate[0]
    latitude = coordinate[1]

    if last_lat && last_long
      d = distance([last_lat, last_long], [latitude, longitude])
    end
    sleep(rand(1.0..1.5))
    firebase.push("v1/locations/#{COMPETITION_ID}/#{CAR_ID}", {
      latitude: latitude,
      longitude: longitude,
      speed: d,
      timestamp: Time.now.to_f,
      course: -1
    })

    last_lat = latitude
    last_long = longitude
  end
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

simulate_fuji(23)
