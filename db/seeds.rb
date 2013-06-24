# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

require 'google_places'

client = GooglePlaces::Client.new(ENV['PLACES_API_KEY'])

# This is the array of places
spots = []

# Set up the types of places to look for
types = %w(amusement_park aquarium art_gallery bakery bank bar beauty_salon bicycle_store book_store bowling_alley cafe campground casino cemetery church city_hall clothing_store convenience_store courthouse department_store electrician electronics_store establishment finance food furniture_store grocery_or_supermarket gym hair_care hardware_store health hindu_temple home_goods_store jewelry_store local_government_office lodging meal_delivery meal_takeaway mosque movie_theater museum night_club park pet_store place_of_worship restaurant school shoe_store shopping_mall spa stadium store synagogue university zoo colloquial_area locality natural_feature neighborhood political point_of_interest)

# Set up the list of (lat, lng) points to search around
points = [{lat: 37.783197, lng: -122.393044}, {lat: 37.772886, lng: -122.419496}, {lat: 37.772886, lng: -122.419496}, {lat: 37.800968, lng:-122.412785}, {lat: 37.800019, lng: -122.441967}, {lat:37.790252 , lng:-122.434586}, {lat:37.781569 , lng: -122.433556}, {lat: 37.760944, lng:-122.433727}, {lat: 37.756873, lng:-122.414158}, {lat:37.748322 , lng:-122.412613}, {lat: 37.741535, lng:-122.411583}]

# Load a small set of places by default, if the "more" argument is set, get more places around the points in the list
if ENV["more"]
  points.each do |point|
    # Get a list of up to 200 places  in a 1000 m radius around the points (radar search)
    spots += client.spots_radar(point[:lat], point[:lng], {:types => types})
  end
else
  # Get a list of up to 20 places in a 1000 m radius around the point (Single page nearby search)
  spots += client.spots(37.772886,-122.419496, {:types => types})
end

spots.each_with_index do |spot, index|

  # Get the details of a spot
  new_spot = client.spot(spot.reference)

  if new_spot
    begin
      # Create a Place instance
      place = Place.create!(
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

    rescue ActiveRecord::RecordInvalid => e
      puts "Models for place #{index} exist"
      place = nil
    end
  end

  if place
    puts "Adding models for place #{index}"

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
    spot_types = new_spot.types

    spot_types.each do |type|
      # Add a Type instance to the place
      place.add_type(type)
    end
  end

end
