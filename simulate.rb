require 'json'
require 'byebug'

GEOJSON_FILE = 'okayama.geojson'

def simulate
  coordinates_from_geojson.each do |coordinate|
    longitude = coordinate[0]
    latitude = coordinate[1]

    puts "#{latitude},#{longitude}"
  end
end

def coordinates_from_geojson
  hash = {}
  File.open(GEOJSON_FILE) do |file|
    hash = JSON.load(file)
  end
  hash['features'].first['geometry']['coordinates']
end

simulate
