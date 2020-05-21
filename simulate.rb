require 'json'
require 'byebug'

GEOJSON_FILE = 'okayama.geojson'

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
    puts "#{latitude},#{longitude},#{d}"

    last_lat = latitude
    last_long = longitude
  end
end

def coordinates_from_geojson
  hash = {}
  File.open(GEOJSON_FILE) do |file|
    hash = JSON.load(file)
  end
  hash['features'].first['geometry']['coordinates']
end

def distance(loc1, loc2)
  rad_per_deg = Math::PI/180  # PI / 180
  rkm = 6371                  # Earth radius in kilometers
  rm = rkm * 1000             # Radius in meters

  dlat_rad = (loc2[0]-loc1[0]) * rad_per_deg  # Delta, converted to rad
  dlon_rad = (loc2[1]-loc1[1]) * rad_per_deg

  lat1_rad, lon1_rad = loc1.map {|i| i * rad_per_deg }
  lat2_rad, lon2_rad = loc2.map {|i| i * rad_per_deg }

  a = Math.sin(dlat_rad/2)**2 + Math.cos(lat1_rad) * Math.cos(lat2_rad) * Math.sin(dlon_rad/2)**2
  c = 2 * Math::atan2(Math::sqrt(a), Math::sqrt(1-a))

  rm * c # Delta in meters
end

simulate
