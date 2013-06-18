# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

require 'google_places'

client = GooglePlaces::Client.new(ENV['PLACES_API_KEY'])

# Get a list of 20 places around the point
spots = client.spots(37.772886,-122.419496)

spots.each_with_index do |spot, index|

  puts "Adding models for place #{index}"

  # Get the details of a spot
  new_spot = client.spot(spot.reference)

  # Create a Place instance
  place = Place.create(
      :permanent_id_num =>new_spot.id,
      :name => new_spot.name,
      :reference => new_spot.reference,
      :address => new_spot.formatted_address,
      :address_lat => new_spot.lat,
      :address_lng => new_spot.lng,
      :phone_number => new_spot.formatted_phone_number,
      :rating => new_spot.rating,
      :url => new_spot.url,
      :website => new_spot.website,
      :price_level => new_spot.price_level,
      :review_summary => new_spot.review_summary
  )

  # Get a list of the spot's reviews
  reviews = new_spot.reviews

  reviews.each do |review|
    # Create a Review instance
    place.reviews.create(
        :author => review.author_name,
        :author_url => review.author_url,
        :text => review.text,
        :time => review.time,
        :rating => review.rating
    )
  end

  # Get a list of the spot's periods
  periods = new_spot.periods

  periods.each do |period|
    # Create a Period instance
    place.periods.create(
        :day => period.day,
        :opening_time => period.opening_time,
        :closing_time => period.closing_time
    )
  end

  # Get a list of the spot's events
  events = new_spot.events

  events.each do |event|
    # Create an Event instance
    place.events.create(
        :id_num => event.event_id,
        :url => event.url,
        :summary => event.summary,
        :start_time => event.start_time
    )
  end

  # Get a list of the spot's types
  types = new_spot.types

  types.each do |type|
    # Add a Category instance to the place
    place.add_category(type)
  end

end
