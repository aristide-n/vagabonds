# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)
require 'google_places'

@client = GooglePlaces::Client.new(ENV['PLACES_API_KEY'])
spots = @client.spots(37.772886,-122.419496)

spots.each do |spot|
  new_spot = @client.spot(spot.reference)
  Place.create(
      :permanent_id =>new_spot.id,
      :name => new_spot.name,
      :reference => new_spot.reference,
      :address => new_spot.formatted_address,
      :address_lat => new_spot.lat,
      :address_lng => new_spot.lng,
      :phone_number => new_spot.formatted_phone_number,
      :rating => new_spot.rating,
      :url => new_spot.url,
      :website => new_spot.website
  )
end