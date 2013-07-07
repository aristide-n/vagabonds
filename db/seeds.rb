#encoding: utf-8

# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = city.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)


if ENV['SEEDS_ENV'] == "development"

  puts "Seeding development database"

  # Places API wrapper
  require 'google_places'

  # Handles document parsing for getting place text from google plus
  require 'nokogiri'

  # Handles document access/fetching
  require 'open-uri'


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
      spots += client.spots_radar(point[:lat], point[:lng], {:types => types, :radius => 50000})
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
            :review_summary => new_spot.review_summary,
            :duration => 1 + Random.rand(4)
        )

      rescue ActiveRecord::RecordInvalid => e
        puts "Models for place #{index} exist"
        place = nil
      end
    end

    if place
      # Pull places text from google plus

      #####REVIEW SUMMARY #######

      # The plus URL of the place
      url = place.url

      # Parse the document with Nokogiri
      data = Nokogiri::HTML(open(url))

      # Target the review summary using its div's class "Jya"
      new_review_summary_element = data.at_css(".Jya")

      new_review_summary = nil

      if new_review_summary_element
        new_review_summary = new_review_summary_element.text.strip
      end

      # Update the Place record if there is a review summary text
      if new_review_summary
        place.update_attributes(:review_summary => new_review_summary)

        # Just a lil notice
        puts "Updated the review summary for place #{index}"
      end

      #####ZAGAT REVIEW #######


      # Add the place's associated model to the DB

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


elsif ENV['SEEDS_ENV'] == "production"

  puts "Seeding production database"

  #------------------------------------ CITY -------------------------------------------------#

  # Create a place
  place = Place.create!(
      :permanent_id_num => "1",
      :name => "Alcatraz",
      :address => "Alcatraz Cruises, LLC\nPier 33, Alcatraz Landing\nSan Francisco, California 94111",
      :phone_number => "415-981-7625",
      :rating => 4.5,
      :website => "www.alcatrazcruises.com",
      :price_level => 2,
      :review_summary => "Alcatraz Island, located in the middle of San Francisco Bay, is a must-see attraction for any visitor to the area.  One of the most infamous prisons in the country for housing notorious criminals, Alcatraz holds much history that will interest buffs and novices alike.  No longer housing prisoners and managed by the National Park Service, Alcatraz allows tourists to visit by the boatload.  Alcatraz was used as a federal maximum security prison from 1934 until 1963, when it was closed due to high costs and security issues. \n\nThe tour is open 7 days a week. Anyone intending to visit Alcatraz should book tickets online in advance from the official website, www.alcatrazcruises.com.  Tours can book up several days in advance, but it is easy to go online to purchase and print tickets.",
      :duration => 3.0
  )

  # Create the associated models: Category, Reviews, Periods, and Photos
    place.category = Category.find_or_create_by_name("city")

    place.reviews.create(
        :author => "Jo P",
        :text => "We were on the first trip leaving for the day. This is a good idea as you have a chance to start the tour before it gets too crowded. The audio tour is the best option. Head phones not only tell you points of interest but give an experience of background sound relevant to the day",
        :time => 1372636800,
        :rating => 5.0
    )

  place.reviews.create(
      :author => "Ken H",
      :text => "This was a very interesting and educational tour. Once there, I found myself very interested and entertained by the audio tour. Do yourself a favor and buy the tickets that not only take you to Alcatraz, but to Angel Island as well. We bought the combo tickets because they were the only tickets left, but Angel Island turned out to be our favorite part of our SF visit.",
      :time => 1372550400,
      :rating => 5.0
  )

  (0..6).each do |day|
    place.periods.create(
        :day => day,
        :opening_time => 845,
        :closing_time => 1830
    )
  end

  #place.photos.create()

  #-------------------------------------------

  # Create a place
  place = Place.create!(
      :permanent_id_num => "2",
      :name => "Pier 39",
      :address => "PIER 39\nBeach Street & The Embarcadero\nSan Francisco, CA 94133",
      :phone_number => "",
      :rating => 4.0,
      :website => "http://www.pier39.com",
      :price_level => 2,
      :review_summary => "This third most visited attraction in the U.S. is a hive of activity with rides, entertainment, restaurants, shops and lively street entertainers. You can easily hop a ferry across the bay to Alcatraz or Tiburon, but don't miss the celebrated sea lion colony that inhabits the nearby abandoned docks.",
      :duration => 1.0
  )

  # Create the associated models: Category, Reviews, Periods, and Photos
  place.category = Category.find_or_create_by_name("city")

  place.reviews.create(
      :author => "jeniffer p",
      :text => "we enjoyed the side shows, street performers and seeing the seals sunbath. lunch at bubba gumps was great.",
      :time => 1372464000,
      :rating => 5.0
  )

  place.reviews.create(
      :author => "mrw811",
      :text => "Great half day trip... but beware, there are lots of things the kids will want to do, could break your travel budget. Great views of the city and of the bay... and sea lions",
      :time => 1372032000,
      :rating => 3.0
  )

  (0..6).each do |day|
    place.periods.create(
        :day => day,
        :opening_time => 1000,
        :closing_time => 2300
    )
  end

  #place.photos.create()

  #-------------------------------------------

  # Create a place
  place = Place.create!(
      :permanent_id_num => "3",
      :name => "Twin Peaks",
      :address => "Twin Peaks\nSan Francisco, CA 94131",
      :phone_number => "",
      :rating => 4.5,
      :website => "",
      :price_level => 0,
      :review_summary => "A twenty-minute ride from downtown, this is the best place to catch a San Francisco sunrise.",
      :duration => 1
  )

  # Create the associated models: Category, Reviews, Periods, and Photos
  place.category = Category.find_or_create_by_name("city")

  place.reviews.create(
      :author => "Wayne R",
      :text => "A visual must see! On a clear day a panoramic view of SF to die for. Have your camera ready for a pic from the west coast around the Golden Gate Bridge thru the Bay Bridge pass Oakland and down to San Jose. A sight that must be seen, especially on a clear day!",
      :time => 1372636800,
      :rating => 5.0
  )

  place.reviews.create(
      :author => "glw1861",
      :text => "We could see most of the eastern side of the city, but the fog made parts of the city disappear from sight",
      :time => 1372550400,
      :rating => 4.0
  )

  (0..6).each do |day|
    place.periods.create(
        :day => day,
        :opening_time => 0,
        :closing_time => 2359
    )
  end

  #place.photos.create()

  #-------------------------------------------

  # Create a place
  place = Place.create!(
      :permanent_id_num => "4",
      :name => "Golden Gate Bridge",
      :address => "Golden Gate Bridge\nSan Francisco, CA 94129-0601",
      :phone_number => "415-921-5858",
      :rating => 4.5,
      :website => "http://www.goldengate.org/",
      :price_level => 1,
      :review_summary => "The Golden Gate Bridge is not the oldest suspension bridge nor the newest.  It is no longer the tallest or the highest.  Yet it remains the most visited and photographed bridge in the world.  If you are able to visit the bridge, you can take a walking tour to help understand why the bridge is so compelling to so many people and why it was so difficult to build.  Parking is free at the GGNRA lots on the east and west sides of the bridge visitors center on Lincoln Blvd. Be sure to bring a camera to capture the great views and a jacket as it is always pretty brisk to very windy.",
      :duration => 1
  )

  # Create the associated models: Category, Reviews, Periods, and Photos
  place.category = Category.find_or_create_by_name("city")

  place.reviews.create(
      :author => "Rosemary D",
      :text => "My son and I took the bus from near our Union Square hotel early in the morning. We had booked a 10:30 tour. It was a beautiful sunny day when we arrived, but by the time our tour started the entire bridge was covered with fog. Our tour guide, Lisa was very knowledgeable, prepared and friendly. The tour gives you a history lesson on the construction of the bridge, and you walk part of the way across the bridge. Although you can walk all around the area and across the bridge on your own, we were glad we spent the money for the tour.",
      :time => 1372636800,
      :rating => 4.0
  )

  place.reviews.create(
      :author => "ramped",
      :text => "Took the blue and gold ferry from Fisherman's Wharf to the bridge, around Alcatraz and back to the Wharf, passed by the sea lions on Pier 39 on the way out. Memorable views. What added to the cruise is that the America's Cup catamarans are out practicing for the Cup competition in August. We also took the Rocket Boat ride, which was a kick; just an extra $10 per person in addition to the ferry toll ($28). Book ahead if you want to land on Alcatraz, those tours sell out quickly during the summer months.",
      :time => 1372550400,
      :rating => 5.0
  )

  (0..6).each do |day|
    place.periods.create(
        :day => day,
        :opening_time => 0,
        :closing_time => 2359
    )
  end

  #place.photos.create()

  #-------------------------------------------

  # Create a place
  place = Place.create!(
      :permanent_id_num => "5",
      :name => "Golden Gate Park",
      :address => "501 Stanyan St\nSan Francisco, CA 94117",
      :phone_number => "415-831-2700",
      :rating => 4.5,
      :website => "http://www.golden-gate-park.com/",
      :price_level => 0,
      :review_summary => "The Golden Gate Park is a large urban park configured in a rectangular shape, much like the famous Central Park of New York city.  The park contains gardens, museums and ample green space.  Popular attractions within the Golden Gate Park include the California Academy of Science, the DeYong Museum, the Japanese tea gardens, Conservatory and the San Francisco Botanical Gardens.  The Golden Gate Park is one of the most heavily visited parks in the United States and one of San Francisco's most important attraction areas.",
      :duration => 1
  )

  # Create the associated models: Category, Reviews, Periods, and Photos
  place.category = Category.find_or_create_by_name("city")

  place.reviews.create(
      :author => "JHR1976",
      :text => "Saw the Californian Science museum and there is so much to see and do, I loved the Aqurium part and seeing the Califorian Crocodile. Walked around the lake and was surprised to see turtles!",
      :time => 1372636800,
      :rating => 5.0
  )

  place.reviews.create(
      :author => "Honeysuckle123",
      :text => "First opportunity for the kids to run freely and enjoy the playground an open spaces. Limited god options so take it with you. Easily accessed by the #5 Fulton St bus from the city. About 30 minute bus ride. Get off at the 8th street stop. We walked from 8th street all the way to the beach, a good 10 km, but a nice walk nonetheless. Saw a coyote. Did not visit the Japanese Tea Gardens as felt it was too expensive. The park is huge so a bike would be a good option to get around.",
      :time => 1372540400,
      :rating => 4.0
  )

  (0..6).each do |day|
    place.periods.create(
        :day => day,
        :opening_time => 0,
        :closing_time => 2359
    )
  end

  #place.photos.create()

  #-------------------------------------------

  # Create a place
  place = Place.create!(
      :permanent_id_num => "6",
      :name => "California Academy of Sciences",
      :address => "55 Music Concourse Dr\nSan Francisco, CA 94118",
      :phone_number => "415-379-8000",
      :rating => 4.5,
      :website => "www.calacademy.org",
      :price_level => 1,
      :review_summary => "The world’s only aquarium-planetarium-rainforest-living museum. Come nose-to-beak with penguins and parrots, watch sharks and sting rays cruise beneath your feet, and feel the spray of the California coast. Fly to Mars (and beyond the Milky Way!) from the safety of your planetarium seat, take a virtual safari in African Hall, or climb into the canopy of a living rainforest. Face your fears—and an albino alligator—inside the Swamp, and meet scientists as they return from research expeditions around the world. From the depths of a Philippine coral reef to the outer reaches of the Universe, it's all inside the California Academy of Sciences.",
      :duration => 3
  )

  # Create the associated models: Category, Reviews, Periods, and Photos
  place.category = Category.find_or_create_by_name("city")

  place.reviews.create(
      :author => "tmmnova",
      :text => "Kids and adults will really enjoy their visit. You've got an aquarium, planetarium and rainforest all wrapped in one. A pristine facility that is extremely well run and very well laid out. A must do if you're hitting the sights in San Francisco. An absolute must do if you have kids.",
      :time => 1372626800,
      :rating => 5.0
  )

  place.reviews.create(
      :author => "coolvaibhav",
      :text => "I liked this place. The information given here was very good for both children and adults. There were many activities that children can do here and learn. Even the store at this place was very rich with scientific things for children. Also one main attraction was earthquake show that was done using 6 digital projectors. How they research and study volcanoes is really amazing. This 20 min show is must watch, very knowledgeable and interesting. Truly scientific height.",
      :time => 1372540400,
      :rating => 4.0
  )

  (0..6).each do |day|
    place.periods.create(
        :day => day,
        :opening_time => 930,
        :closing_time => 1700
    )
  end

  #place.photos.create()

  #-------------------------------------------

  # Create a place
  place = Place.create!(
      :permanent_id_num => "7",
      :name => "Haight-Ashbury",
      :address => "Haight-Ashbury, San francisco CA",
      :phone_number => "",
      :rating => 4.0,
      :website => "",
      :price_level => 0,
      :review_summary => "Center of the long-gone hippie culture of the 1960s, this trendy neighborhood is now a whole new scene with upscale boutiques, Internet cafes and hip restaurants.",
      :duration => 2
  )

  # Create the associated models: Category, Reviews, Periods, and Photos
  place.category = Category.find_or_create_by_name("city")

  place.reviews.create(
      :author => "CovingtonCat",
      :text => "I was in high school on a field trip to San Francisco when I saw my first hippy. On a subsequent school trip our advisor allowed the bus driver to go through Haight-Ashbury. My guess it was to discourage us from running off to join the kids who thronged here at the time. It wasn't a pretty sight. Today, however, Haight Street is clean, with many nice stores & restaurants. There's still a counter-culture vibe (I smelled pot a couple times as I walked down the street). Many stores cater to the nostalgia but also serve a need for current residents. I'm not sure what it means that I found a Ben & Jerry's store at the corner of Haight & Ashbury. Fitting compliment to the neighborhood or corporate advantage-taking? Probably a little of both. Pick a restaurant and sit facing the street. You'll see all kinds of people walking by. Parking is on street, at meters. Or take one of the many tours that come through the area and get off the bus to wander around a while.",
      :time => 1372426800,
      :rating => 4.0
  )

  place.reviews.create(
      :author => "Tristelle",
      :text => "I actually come here almost every day. I am a native of the SF Bay Area. Not old enough to have experienced legendary Haight-Ashbury action first hand, but I do appreciate it's history as an on-looker. So, if you are into the history, then this might be for you. It is especially amazing for photographers--amatures and/or professionals alike love it. And, I can't emphasize enough that you really have to be a special person and really love diversity to truly enjoy this experience. Otherwise, you will probably be disappointed.\n In regard to those comments saying that 'no one will bother you', this is completely untrue. I often grab a bite to eat and walk around the area, and am bothered almost daily. I could have a half eaten pizza or a nearly empty coffee in my hand, and someone will 9 times out of 10 ask me \"are you going to eat that?\" One time in particular, I threw a pizza crust in the garbage, only to turn around and witness someone suddenly picking it out to eat it.\n Anyway, if this type of thing doesn't phase you, then awesome.\n P.S. Never drive here. Take public transportation, walk, or bike rental is the way to go!",
      :time => 1372540400,
      :rating => 4.0
  )

  (0..6).each do |day|
    place.periods.create(
        :day => day,
        :opening_time => 0,
        :closing_time => 2359
    )
  end

  #place.photos.create()

  #-------------------------------------------

  # Create a place
  place = Place.create!(
      :permanent_id_num => "8",
      :name => "Chinatown",
      :address => "Chinatown, San Francisco CA",
      :phone_number => "",
      :rating => 4.0,
      :website => "http://www.sanfranciscochinatown.com/",
      :price_level => 0,
      :review_summary => "San Francisco's Chinatown is the largest outside of Asia.  It is a place many visitors want to see and put high on their list of places to go.  But read the reviews and many are quite negative.  Why?  Because it is an intense, densely populated area that still retains its ethnic identity.  If all of San Francisco's 49 square miles were as closely packed as Chinatown, the city's population would be 8 MILLION (rather than about 800,000). ",
      :duration => 2
  )

  # Create the associated models: Category, Reviews, Periods, and Photos
  place.category = Category.find_or_create_by_name("city")

  place.reviews.create(
      :author => "Kelli S",
      :text => "Definitely a must-see if you enjoy cheesy touristy Chinatown experiences. It's a great place to pick up souvenirs and knickknacks to take back home. Also, you can take the cable car to get there!",
      :time => 1371426800,
      :rating => 4.0
  )

  place.reviews.create(
      :author => "CovingtonCat",
      :text => "It's been a long while since I last visited San Francisco and Chinatown. Some things don't change (much). Visiting Chinatown should be done as an adventure - you're site-seeing, maybe trying a new food, not spending a lot of money to do it. First off, don't buy something in the first shops you visit near the gate on Grant. You'll probably find the same items farther up Grant for a little less money. Not much less, but still less. You'll find some of the same items in several stores. There are some stores selling high-priced luxury items and many selling tourist kitsch items. Window shop the first, go into the latter. You'll thank me later. Get all your t-shirts here since they'll be cheaper than anywhere else. But check them out closely to be sure you're not getting a second. Walk up one side of Grant, then return on the other. Have fun.",
      :time => 1372540400,
      :rating => 4.0
  )

  (0..6).each do |day|
    place.periods.create(
        :day => day,
        :opening_time => 0,
        :closing_time => 2359
    )
  end

  #place.photos.create()

  #-------------------------------------------

  # Create a place
  place = Place.create!(
      :permanent_id_num => "9",
      :name => "Lombard Street",
      :address => "Lombard St, San Francisco\nCA 94133",
      :phone_number => "",
      :rating => 4.5,
      :website => "",
      :price_level => 0,
      :review_summary => "San Francisco's Chinatown is the largest outside of Asia.  It is a place many visitors want to see and put high on their list of places to go.  But read the reviews and many are quite negative.  Why?  Because it is an intense, densely populated area that still retains its ethnic identity.  If all of San Francisco's 49 square miles were as closely packed as Chinatown, the city's population would be 8 MILLION (rather than about 800,000). ",
      :duration => 1
  )

  # Create the associated models: Category, Reviews, Periods, and Photos
  place.category = Category.find_or_create_by_name("city")

  place.reviews.create(
      :author => "Cody Rapol",
      :text => "It's pretty cool to see, but what blows my mind is that people really do live on this street.",
      :time => 1372326800,
      :rating => 5.0
  )

  place.reviews.create(
      :author => "Nadia Nunes",
      :text => "Good point of visit in San Francisco specially because of its difference between the other streets in the neighborhood. The landscape is really beautiful specially in the afternoon when the sun is shinning.",
      :time => 1372540400,
      :rating => 4.0
  )

  (0..6).each do |day|
    place.periods.create(
        :day => day,
        :opening_time => 0,
        :closing_time => 2359
    )
  end

  #place.photos.create()

  #-------------------------------------------

  # Create a place
  place = Place.create!(
      :permanent_id_num => "10",
      :name => "Coit tower",
      :address => "1 Telegraph Hill Blvd\nSan Francisco, CA 94133",
      :phone_number => "",
      :rating => 4.0,
      :website => "",
      :price_level => 2,
      :review_summary => "Monument built in honor of the city's volunteer firemen, with an observation deck that provides a great view of San Francisco.",
      :duration => 1
  )

  # Create the associated models: Category, Reviews, Periods, and Photos
  place.category = Category.find_or_create_by_name("city")

  place.reviews.create(
      :author => "oceanair73",
      :text => "It was a bit out of the way of the main sights so we caught a taxi up to the tower, which was the best idea. The murals were not available for viewing unfortunately. We found the entry signs for tickets confusing but the short trip in the manned lift was worth it for the 360 degree views, including Lombard Street curves! Enjoyed the walk down the north side steps to Napier Lane, a boarded walk alongside attractive gardens and homes built on the hillside.",
      :time => 1372377600,
      :rating => 4.0
  )

  place.reviews.create(
      :author => "SYD-LHR",
      :text => "The views from the top are amazing, if a little restricted by all the safety installations. The ride up in the lift is a tad cramped but the reward certainly makes up for the discomfort. The sweeping views of San Francisco and the Bay Area are breathtaking and you get an amazing perspective of the Hilly city.",
      :time => 1372540400,
      :rating => 4.0
  )

  (0..6).each do |day|
    place.periods.create(
        :day => day,
        :opening_time => 1000,
        :closing_time => 1830
    )
  end

  #place.photos.create()

  #-------------------------------------------

  # Create a place
  place = Place.create!(
      :permanent_id_num => "11",
      :name => "Ferry Building Marketplace",
      :address => "1 Sausalito - San Francisco Ferry Bldg\nSan Francisco, CA 94111",
      :phone_number => "415-983-8030",
      :rating => 5.0,
      :website => "www.ferrybuildingmarketplace.com",
      :price_level => 0,
      :review_summary => "A city landmark transformed into a gourmet food emporium and farmers market.",
      :duration => 2
  )

  # Create the associated models: Category, Reviews, Periods, and Photos
  place.category = Category.find_or_create_by_name("city")

  place.reviews.create(
      :author => "Argyletraveler339",
      :text => "Great spot for a little shopping and a lot of eating! Grab some Cowgirl Creamery cheese and Acme bread and you're set. Nice wine bar too (no corkage if you buy a bottle of wine from the adjacent store).",
      :time => 1372377600,
      :rating => 5.0
  )

  place.reviews.create(
      :author => "Myra K",
      :text => "This is a great place to see a lot in one spot and have tons of choices. We had a great lunch and enjoyed it outside and watched the boats coming and going. Then we browsed the sweets and the rest of the offerings in the market. It was fun.",
      :time => 1372540400,
      :rating => 4.0
  )

  (0..6).each do |day|
    place.periods.create(
        :day => day,
        :opening_time => 1000,
        :closing_time => 1800
    )
  end

  #place.photos.create()

  #-------------------------------------------

  # Create a place
  place = Place.create!(
      :permanent_id_num => "12",
      :name => "Filoli",
      :address => "86 Canada Road\nWoodside, CA, United States",
      :phone_number => "650-364-8300",
      :rating => 4.5,
      :website => "http://www.filoli.org/",
      :price_level => 0,
      :review_summary => "Filoli Center is a lovely country estate with beautiful gardens, an historic site of the National Trust for Historic Preservation. Open Tues-Sun, visitors are welcome from February to late October.",
      :duration => 1
  )

  # Create the associated models: Category, Reviews, Periods, and Photos
  place.category = Category.find_or_create_by_name("city")

  place.reviews.create(
      :author => "Rachael H",
      :text => "What a fantastic place! No matter what time of the year there are beautiful flowers. I get so happy going to Filofi and walking around the spacious gardens. Don&#39;t think about it, JUST GO!!" ,
      :time => 1367366143,
      :rating => 5.0
  )

  place.reviews.create(
      :author => "Rachelle Berger",
      :text => "This is the house they used to film Dynasty even though the show took place in Colorado. However , this great house is in California. The Irish gardens around the house are beautiful. Weddings take place here. What a wonderful place.",
      :time => 1363360170,
      :rating => 4.0
  )

  place.reviews.create(
      :author => "Kamal Singh",
      :text => "Lots of very nice flower gardens. The main house is also maintained very well, worth visiting if around this area.",
      :time => 1369006866,
      :rating => 4.5
  )

  (0..6).each do |day|
    place.periods.create(
        :day => day,
        :opening_time => 1000,
        :closing_time => 1530
    )
  end

  #place.photos.create()

  #-------------------------------------------

  # Create a place
  place = Place.create(
      :permanent_id_num => "13",
      :name => "San Francisco Botanical Garden Society",
      :address => "1199 9th Avenue, San Francisco, CA, United States",
      :phone_number => "(415) 661-1316",
      :rating => 4.5,
      :website => "http://www.sfbg.org/",
      :price_level => 0,
      :review_summary => "San Francisco Botanical Garden sits on 55 acres (22.3 ha) in Golden Gate Park. There are over 50,000 individual plants, with a focus on Magnolias, Mediterranean climate and cloud forest plants.",
      :duration => 1
  )

  # Create the associated models: Category, Reviews, Periods, and Photos
  place.category = Category.find_or_create_by_name("city")

  place.reviews.create(
      :author => "Michael Lawler",
      :text => "Great place, large area. Some great places: New Zealand, Garden of Fragrance, and an Exhibition Garden. Plenty of open space. Free for residents, only $7 for adults and $15 family pass. Good times, highly recommended.",
      :time => 1372664586,
      :rating => 5.0
  )

  place.reviews.create(
      :author => "Samantha Strauss",
      :text => "Don&#39;t have a green thumb? No worries, the SF Botanical Garden has you taken care of with 55 acres of flowers, foliage, and mystical pathways. Not only is the SF Botanical Garden home of the one of the largest magnolia collections in the world, it also has over 8000 different kinds of plants, endless open space for picnics, and plenty of benches to relax on. Every day of the year you&#39;ll see something different in the park, from Poppys in the Native California Garden, to members of the amazing Proteaceae family in the Australian garden. The garden is open year-round and free for SF Residents as well as the 2nd Tuesday of every month for visitors. Move your life outdoors, and take in our beautiful world at the SF Botanical Garden!",
      :time => 1363804576,
      :rating => 4.0
  )

  place.reviews.create(
      :author => "Moritz Hoffmann",
      :text => "Idyllic place in San Francisco. Quite empty before noon, do if you want to take pictures come early!",
      :time => 1371237337,
      :rating => 4.5
  )

  place.periods.create(
      :day => 0,
      :opening_time => 1000,
      :closing_time => 1700
  )
  place.periods.create(
      :day => 1,
      :opening_time => 800,
      :closing_time => 1630
  )
  place.periods.create(
      :day => 2,
      :opening_time => 800,
      :closing_time => 1630
  )
  place.periods.create(
      :day => 3,
      :opening_time => 800,
      :closing_time => 1630
  )
  place.periods.create(
      :day => 4,
      :opening_time => 800,
      :closing_time => 1630
  )
  place.periods.create(
      :day => 5,
      :opening_time => 800,
      :closing_time => 1630
  )
  place.periods.create(
      :day => 6,
      :opening_time => 1000,
      :closing_time => 1700
  )

#-------------------------------------------

  # Create a place
  place = Place.create(
      :permanent_id_num => "14",
      :name => "Conservatory of Flowers",
      :address => "100 John F Kennedy Drive, San Francisco, CA, United States",
      :phone_number => "(415) 831-2090",
      :rating => 4.5,
      :website => "http://conservatoryofflowers.org/",
      :price_level => 0,
      :review_summary => "The Conservatory of Flowers has captivated guests for more than a century. This gem of Victorian architecture has a long and storied history, and is the oldest wood and glass conservatory in America.",
      :duration => 1
  )

  # Create the associated models: Category, Reviews, Periods, and Photos
  place.category = Category.find_or_create_by_name("city")

  place.reviews.create(
      :author => "David Lippman",
      :text => "A great little spot to stop and smell the flowers. Situated in a wonderful part of the park, with a fantastic dahlia garden just outside (dahlias are seasonal, so make sure you see them in bloom, you won&#39;t regret it). Given the relatively low cost of admission, your visit can be a quick walk through, glancing over the fantastic variety of flowers, or you can dawdle, absorbing the unique beauty of each specimen. Multiple rooms, including a pond area, with no space left unused or underused make for an engaging experience.",
      :time => 1369851701,
      :rating => 4.0
  )

  place.reviews.create(
      :author => "John Favry",
      :text => "Went here with family on a Sunday afternoon. The views were breathtaking and I found the experience to be quite spiritual in nature. It&#39;s a botanist&#39;s dream, and having a green thumb myself I really enjoyed everything about the Conservatory from the Amazon water lilies to the Victorian greenhouse!",
      :time => 1368548774,
      :rating => 4.5
  )

  place.reviews.create(
      :author => "Bernhard Perchinig",
      :text => "An extrmely beautiful setting, a marvellous hosue for flowers located in the most impressing park of the city. I particularly liked the section for the exotic flowers and the section on gardening. I have seen several flower houses before, but this in one of the best. And it fits extremelz well into the large park.",
      :time => 1364500733,
      :rating => 5.0
  )

  (0..6).each do |day|
    place.periods.create(
        :day => day,
      :opening_time => 1000,
      :closing_time => 1600
    )
  end

  #------------------------------------ NATURE -------------------------------------------------#

  # Create a place
  place = Place.create(
      :permanent_id_num => "20",
      :name => "Mount Tamalpais State Park",
      :address => "Mill Valley, CA, United States",
      :phone_number => "(415) 388-2070",
      :rating => 5.0,
      :website => "http://parks.ca.gov",
      :price_level => 0,
      :review_summary => "Spread around spectacular 2,571-foot tall Mount Tamalpais are hundreds of miles of trails and tens of thousands of acres of redwood forests, oak woodlands, chaparral scrub, grasslands, and beaches.",
      :duration => 2,
  )

  # Create the associated models: Category, Reviews, Periods, and Photos
  place.category = Category.find_or_create_by_name("nature")

  place.reviews.create(
      :author => "Steven La Vinger",
      :text => "Love the place...",
      :time => 1357999000,
      :rating => 5.0
  )

  place.reviews.create(
      :author => "Anton P. K.",
      :text => "One of the best hikes in bay area!!! Great view of San Francisco!!!",
      :time => 1325179233,
      :rating => 5.0
  )

  (0..6).each do |day|
    place.periods.create(
        :day => day,
        :opening_time => 700,
        :closing_time => 2000
    )
  end

#-------------------------------------------

  # Create a place
  place = Place.create(
      :permanent_id_num => "21",
      :name => "Coyote Hills Regional Park",
      :address => "8000 Patterson Ranch Road, Fremont, CA, United States",
      :phone_number => "(510) 544-3220",
      :rating => 4.5,
      :website => "http://www.ebparks.org/parks/coyote_hills",
      :price_level => 0,
      :review_summary => "Comprised of nearly 978 acres of marshland and rolling grassland covered hills, this busy park is located along the eastern shore of San Francisco Bay, northwest of the cities of Fremont and Newark.",
      :duration => 2
  )

  # Create the associated models: Category, Reviews, Periods, and Photos
  place.category = Category.find_or_create_by_name("nature")

  place.reviews.create(
      :author => "Andy Xiang",
      :text => "awesome bay view from most part of the park. great hideout.",
      :time => 1371365751,
      :rating => 5.0
  )

  place.reviews.create(
      :author => "Praveen Kallakuri",
      :text => "As others said, its a great place for family, little children. Short hikes are rewarded with pleasing views.",
      :time => 1366293409,
      :rating => 4.0
  )

  place.reviews.create(
      :author => "Caylon Neely",
      :text => "Fun place, good views and easy trails.",
      :time => 1365368620,
      :rating => 4.5
  )

  place.reviews.create(
      :author => "Charee Kinser",
      :text => "we love hiking here, family favorite!",
      :time => 1364792816,
      :rating => 4.5
  )

  (0..6).each do |day|
    place.periods.create(
        :day => day,
        :opening_time => 700,
        :closing_time => 2000
    )
  end

#-------------------------------------------

  # Create a place
  place = Place.create(
      :permanent_id_num => "22",
      :name => "Briones Regional Park",
      :address => "5363 Alhambra Valley Rd, Martinez, CA, United States",
      :phone_number => "(888) 327-2757",
      :rating => 4.5,
      :website => "http://www.ebparks.org/parks/briones",
      :price_level => 0,
      :review_summary => "With its rolling, grassy hills and secluded, shady canyons, Briones is a secret wilderness surrounded by the towns of central Contra Costa County.",
      :duration => 3
  )

  # Create the associated models: Category, Reviews, Periods, and Photos
  place.category = Category.find_or_create_by_name("nature")

  place.reviews.create(
      :author => "saber ogden",
      :text => "get the f@&amp;# away",
      :time => 1368562072,
      :rating => 4.0
  )

  place.reviews.create(
      :author => "Lee Fife",
      :text => "beautiful and easy off leash for dog ..",
      :time => 1316307012,
      :rating => 5.0
  )

  (0..6).each do |day|
    place.periods.create(
        :day => day,
        :opening_time => 600,
        :closing_time => 2000
    )
  end

#-------------------------------------------

  # Create a place
  place = Place.create(
      :permanent_id_num => "23",
      :name => "Pleasanton Ridge Regional Park",
      :address => "9895 Foothill Rd, Sunol, CA, United States",
      :phone_number => "(925) 931-1335",
      :rating => 5.0,
      :website => "http://www.ebparks.org/parks/pleasanton",
      :price_level => 0,
      :review_summary => "This beautiful 5,271-acre parkland is on the oak-covered ridge overlooking Pleasanton and the Livermore Valley from the west.",
      :duration => 3
  )

  # Create the associated models: Category, Reviews, Periods, and Photos
  place.category = Category.find_or_create_by_name("nature")

  place.reviews.create(
      :author => "Tom A",
      :text => "A nice dog-friendly park. Dogs are allowed off-leash just past the fence around the parking lot. There are several easy loop trails one can take up the ridge. While this park does have cows, unlike Mission Peak and Del Valle, these cows aren&#39;t aggressive and won&#39;t charge you for no apparent reason. (Perhaps they aren&#39;t given the same steroids/antibiotics???). The ridge walk has a pleasant surprise at the 1.5 mile point from the parking lot. There is a water tap with municipal water on the ridge. On a hot day when a dog will drink a liter of water in one sitting this is a very nice treat to not have to haul an extra one or two 2-litter bottles up with you.",
      :time => 1312332141,
      :rating => 5.0
  )

  (0..6).each do |day|
    place.periods.create(
        :day => day,
        :opening_time => 600,
        :closing_time => 2000
    )
  end

#-------------------------------------------
  # Create a place
  place = Place.create(
      :permanent_id_num => "24",
      :name => "Baylands Nature Preserve",
      :address => "2775 Embarcadero Way, Palo Alto, CA, United States",
      :phone_number => "(650) 329-2506",
      :rating => 4.0,
      :website => "http://www.cityofpaloalto.org/depts/csd/parks_and_open_space/preserves_and_open_spaces/the_baylands.asp",
      :price_level => 0,
      :review_summary => "Bounded by Mountain View and East Palo Alto, the 1,940-acre Baylands Preserve is the largest tract of undisturbed marshland remaining in the San Francisco Bay.",
      :duration => 3
  )

  # Create the associated models: Category, Reviews, Periods, and Photos
  place.category = Category.find_or_create_by_name("nature")

  place.reviews.create(
      :author => "Kristen Vacketta",
      :text => "This a great area to go running, biking, or just walking. I love to take the kids I babysit here and spend a nice day checking out the weather, scenery, and counting the birds and planes that fly over head nearby at the Palo Alto airport. Nice trail - bring your good shoes!",
      :time => 1370719273,
      :rating => 4.0
  )

  place.reviews.create(
      :author => "David Bailey",
      :text => "Oh yeah, really love it here. Cozy nature center with aquarium that&#39;s nice on a foggy day. Boardwalk out to the wind whipped edge of the bay. Lots of birds. And a short hike to the edge of the airport where you can watch planes from atop a hill.",
      :time => 1289944916,
      :rating => 5.0
  )

  place.reviews.create(
      :author => "Pedro U",
      :text => "Good place for family.",
      :time => 1354217184,
      :rating => 3.0
  )

  place.reviews.create(
      :author => "Mauricio Baiano",
      :text => "If it wasn&#39;t for the airplanes noise, out would be a perfect relaxing area.",
      :time => 1319307609,
      :rating => 4.0
  )

  place.periods.create(
      :day => 0,
      :opening_time => 1300,
      :closing_time => 1700
  )
  place.periods.create(
      :day => 2,
      :opening_time => 1000,
      :closing_time => 1700
  )
  place.periods.create(
      :day => 3,
      :opening_time => 1000,
      :closing_time => 1700
  )
  place.periods.create(
      :day => 4,
      :opening_time => 1400,
      :closing_time => 1700
  )
  place.periods.create(
      :day => 5,
      :opening_time => 1400,
      :closing_time => 1700
  )
  place.periods.create(
      :day => 6,
      :opening_time => 1300,
      :closing_time => 1700
  )

#-------------------------------------------

  # Create a place
  place = Place.create(
      :permanent_id_num => "25",
      :name => "Muir Woods National Monument",
      :address => "Mill Valley, CA 94941‎",
      :phone_number => "(415) 388-2596",
      :rating => 4.5,
      :website => "http://www.nps.gov/muwo/index.htm",
      :price_level => 1,
      :review_summary => "When John Muir learned that William and Elizabeth Kent were naming a redwood forest near San Francisco in his honor, he declared, \"This is the best tree-lovers monument that could possibly be found in all the forests of the world.\" The couple had purchased the land to preserve its beauty and restful wilderness; and in 1908, they donated it to the federal governent to protect it from destruction.",
      :duration => 2
  )

  # Create the associated models: Category, Reviews, Periods, and Photos
  place.category = Category.find_or_create_by_name("nature")

  place.reviews.create(
      :author => "redyoga",
      :text => "My niece and I visited Muir Woods on a Friday. Definitely get there early, as there is very limited parking! The hike along the boardwalk is easy and beautiful, and these are old growth redwoods. It's cool and beautiful and other-worldly. We did a longer hike, too, but once you get above the valley floor the redwoods are not as majestic. I definitely recommend lunch at the café; we had the deluxe grilled cheese sandwich (made with Mt. Tam cheese) and tomato soup, and declared it the best ever. The gift shop is amazing but the visitor center is a bit lacking (it seems to be more of a gift shop; I would have liked to have seen more historical information). A must visit in the Bay Area!",
      :time => 1312332141,
      :rating => 4.5
  )

  (0..6).each do |day|
    place.periods.create(
        :day => day,
        :opening_time => 600,
        :closing_time => 2000
    )
  end

#-------------------------------------------

  # Create a place
  place = Place.create(
      :permanent_id_num => "26",
      :name => "Angel Island State Park",
      :address => "Pier 41, San Francisco, CA 94109‎",
      :phone_number => "415 435 1915",
      :rating => 4.5,
      :website => "http://angelisland.org/",
      :price_level => 2,
      :review_summary => "The largest island in San Francisco Bay features magnificent views of Marin County and San Francisco, while offering a wide variety of recreation for outdoor enthusiasts. ",
      :duration => 3
  )

  # Create the associated models: Category, Reviews, Periods, and Photos
  place.category = Category.find_or_create_by_name("nature")

  place.reviews.create(
      :author => "Ken H",
      :text => "Probably my favorite thing in SF. I really enjoyed touring this island and the tour guide was an excellent, all the staff was nice. The beauty of the island was spectacular and the smell of the Eucalyptus trees was amazing. I liked this better than Alcatraz (which I also liked).",
      :time => 1312332141,
      :rating => 5.0
  )

  place.reviews.create(
      :author => "PaulaDi-47",
      :text => "The round trip boat ride (2 single tickets) was only $17 ( and about $10 for age 65+) on the Blue and White ferry. I feel that history should not be forgotten, and I had no idea how Chinese immigrants suffered at this \"Ellis Island\" of San Francisco. The four of us, in our 60's, missed the $5 shuttle. BIG MISTAKE! The climb on trail and steps to the top rattled my nerves, and I felt ill, so it was difficult to enjoy the great views. Only people as fit as a fiddle should attempt the climb. Had we taken the shuttle like most tourists, I'd have rated this attraction a five, and because I like history, I'd have climbed down the hill to the building that housed the immigrants. Music plays as people sip drinks on each Sunday afternoon, but we walked past Grandpa Banana and his band, eager to catch the next ferry back to San Francisco. PS People who like to hike or bike would not share my feelings about the shuttle.",
      :time => 1354217184,
      :rating => 4.0
  )

  (0..6).each do |day|
    place.periods.create(
        :day => day,
        :opening_time => 900,
        :closing_time => 1800
    )
  end

#-------------------------------------------

  # Create a place
  place = Place.create(
      :permanent_id_num => "27",
      :name => "Lands End",
      :address => "Western End Geary Blvd., San Francisco, CA 94121‎",
      :phone_number => "415-556-8642",
      :rating => 5.0,
      :website => "",
      :price_level => 2,
      :review_summary => "Series of hiking trails that connect the Legion of Honor with the Golden Gate Bridge.",
      :duration => 2
  )

  # Create the associated models: Category, Reviews, Periods, and Photos
  place.category = Category.find_or_create_by_name("nature")

  place.reviews.create(
      :author => "neopier",
      :text => "A very nice view from the pacific ocean, with a huuuuuge beach on the south and nice walking possibilities to the north, next to rough, nice looking cliffs (but still on an actual path). Very nice view of the golden gate from there!",
      :time => 1312332141,
      :rating => 5.0
  )

  place.reviews.create(
      :author => "Chloe R",
      :text => "our lands end photo stop next to the legion of honor was perfect-great views of baker beach and the golden gate bridge",
      :time => 1354217184,
      :rating => 5.0
  )

  (0..6).each do |day|
    place.periods.create(
        :day => day,
        :opening_time => 0,
        :closing_time => 2359
    )
  end

#-------------------------------------------

  # Create a place
  place = Place.create(
      :permanent_id_num => "28",
      :name => "Black Diamond Mines Regional Preserve",
      :address => "5175 Somersville Road, Antioch, CA, United States",
      :phone_number => "(888) 327-2757",
      :rating => 4.5,
      :website => "http://www.ebparks.org/parks/black_diamond",
      :price_level => 1,
      :review_summary => "The East Bay Regional Park District began acquiring land for Black Diamond Mines Regional Preserve in the early 1970s. Today, most of the mining district is within the Preserve's nearly 6,096 acres. T",
      :duration => 3
  )

  # Create the associated models: Category, Reviews, Periods, and Photos
  place.category = Category.find_or_create_by_name("nature")

  place.reviews.create(
      :author => "Daniel Herzberg",
      :text => "Love this place. I think of it as a massive spacious dog park with open spaces, sweeping jaw dropping views, few people (generally friendly), and a enough variety to stay interesting. I go here 1-4x/week. Just went yesterday on a 4 hour walk....came home inspired. Highly reccomend!",
      :time => 1362328776,
      :rating => 5.0
  )

  place.reviews.create(
      :author => "Reyna Vasquez",
      :text => "Love this place. I come here to walk the trails as well as go on tours of the mines. It has a really great history. This place has a calming effect.",
      :time => 1351967853,
      :rating => 5.0
  )

  place.reviews.create(
      :author => "Max Davis",
      :text => "Excellent slideshow and underground tour of the Hazel-Atlas sand mines, nice rugged, open park.",
      :time => 1362586693,
      :rating => 4.0
  )

  place.reviews.create(
      :author => "Jonas Bo Hansen",
      :text => "Preserve is open every day, but not always with staff - eg. Not on July 4. To bad because they close all the mines. Go there when the mines are open otherwise the experience us somewhat disappointing. Another tip is to only go there on cooler days. There may be very hot. Note only entrance from Summerville ave. Fee 5$",
      :time => 1309882933,
      :rating => 4.0
  )

  (1..5).each do |day|
    place.periods.create(
        :day => day,
      :opening_time => 800,
      :closing_time => 2000
    )
  end

#------------------------------------ FOOD -------------------------------------------------#

  # Create a place
  place = Place.create(
      :permanent_id_num => "41",
      :name => "Jardinière",
      :address => "300 Grove Street, San Francisco, CA, United States",
      :phone_number => "(415) 861-5555",
      :rating => 4.5,
      :website => "http://www.jardiniere.com/",
      :price_level => 4,
      :review_summary => "JardiniÃ¨re features the award winning French-California cuisine of Chef Traci Des Jardins. We specialize in utilizing sustainable and local ingredients whenever possible.",
      :duration => 1.0
  )

  # Create the associated models: Category, Reviews, Periods, and Photos
  place.category = Category.find_or_create_by_name("food")

  place.reviews.create(
      :author => "Andy G",
      :text => "Great food! Great Service. Lovely Atmosphere. I&#39;d eat here any day.",
      :time => 1366933769,
      :rating => 5.0
  )

  place.reviews.create(
      :author => "Ernest B.",
      :text => "We had a phenomenal time. Our waiter, Wilson, was most welcoming &amp; knowledgeable . The food was excellent. My steak was cooked beautifully and perfectly seasoned. My friend&#39;s tagliatelle was tender and delicious. The risotto was creamy and tasty. I have always been blown away by the service. The food has always been great. I can&#39;t wait to come back.",
      :time => 1368476452,
      :rating => 4.0
  )

  place.reviews.create(
      :author => "Josh Baskin",
      :text => "Such a romantic restaurant. The dining room upstairs exudes french style and class and the food was amazing. The risotto appetizer was the best risotto I have ever had, and the Waygu beef was cooked perfectly. Retreated to the bar downstairs after dinner and had some great whisky drinks.",
      :time => 1362086531,
      :rating => 4.5
  )

  place.periods.create(
      :day => 0,
      :opening_time => 1700,
      :closing_time => 2100
  )
  place.periods.create(
      :day => 1,
      :opening_time => 1700,
      :closing_time => 2100
  )
  place.periods.create(
      :day => 2,
      :opening_time => 1700,
      :closing_time => 2200
  )
  place.periods.create(
      :day => 3,
      :opening_time => 1700,
      :closing_time => 2200
  )
  place.periods.create(
      :day => 4,
      :opening_time => 1700,
      :closing_time => 2200
  )
  place.periods.create(
      :day => 5,
      :opening_time => 1700,
      :closing_time => 2300
  )
  place.periods.create(
      :day => 6,
      :opening_time => 1700,
      :closing_time => 2300
  )

#-------------------------------------------

  # Create a place
  place = Place.create(
      :permanent_id_num => "42",
      :name => "Patxi's",
      :address => "511 Hayes Street, San Francisco, California, United States",
      :phone_number => "(415) 558-9991",
      :rating => 4.0,
      :website => "http://www.patxispizza.com/",
      :price_level => 2,
      :review_summary => "Great Chicago deep dish and thin crust pizzas, beers and wine! We also deliver!",
      :duration => 1.0
  )

  # Create the associated models: Category, Reviews, Periods, and Photos
  place.category = Category.find_or_create_by_name("food")

  place.reviews.create(
      :author => "Randall Coard",
      :text => "I am a New Yorker and I love pizza. This is differnet than NY pizza but it was a pleasurable experience. Th pizza was very filling and tasty. I would definately return fo rmore. If you like Chicago pizza try this",
      :time => 1371325901,
      :rating => 4.0
  )

  place.reviews.create(
      :author => "Shaan Desai",
      :text => "Went to the locations in Palo Alto and Hayes Valley. The deep dish offered here is fantastic - &quot;the best I&#39;ve tasted outside of Chi-town&quot; according to one of my roommates. Little pricy but well worth it.",
      :time => 1371341559,
      :rating => 4.0
  )

  place.reviews.create(
      :author => "Chris Jennings",
      :text => "I know everyone loves Little Star, and rightfully so. But I have become a Patxi&#39;s devotee. The big reason is the vegan cheese. You can have a giant vegan deep dish pizza delivered to your home in no time, can&#39;t beat that. Not to mention that the folks I&#39;ve met at Patxi&#39;s are second to none. They even donate a sizable amount to charity each month, what more could you want?",
      :time => 1367330474,
      :rating => 4.0
  )

  place.reviews.create(
      :author => "Luke Segars",
      :text => "Patxi&#39;s is utterly delicious. I go here about once a month and they amaze me every time. Going in off-hours is better if possible. The place is a bit small so getting seated can take a while. Luckily they let you order while you wait (cooking your pizza will take ~45 min) and you can grab beer / drinks while you wait as well. Service is fine, nothing to write home about but no complaints either.",
      :time => 1366854085,
      :rating => 4.0
  )

  place.periods.create(
      :day => 0,
      :opening_time => 1100,
      :closing_time => 2200
  )
  place.periods.create(
      :day => 1,
      :opening_time => 1100,
      :closing_time => 2200
  )
  place.periods.create(
      :day => 2,
      :opening_time => 1100,
      :closing_time => 2200
  )
  place.periods.create(
      :day => 3,
      :opening_time => 1100,
      :closing_time => 2200
  )
  place.periods.create(
      :day => 4,
      :opening_time => 1100,
      :closing_time => 2230
  )
  place.periods.create(
      :day => 5,
      :opening_time => 1100,
      :closing_time => 2230
  )
  place.periods.create(
      :day => 6,
      :opening_time => 1100,
      :closing_time => 2230
  )

#-------------------------------------------

  # Create a place
  place = Place.create(
      :permanent_id_num => "43",
      :name => "Bossa Nova",
      :address => "139 8th Street, San Francisco, CA, United States",
      :phone_number => "(415) 558-8004",
      :rating => 4.0,
      :website => "http://www.bossahome.com/",
      :price_level => 1,
      :review_summary => "Created with the look and feel of the Favela, Bossa Nova SF brings you the flavor of Rio's Streets to San Francisco. The Favela (Rio's vibrant ghetto culture)is the birthplace of Bossa Nova music.",
      :duration => 1.0
  )

  # Create the associated models: Category, Reviews, Periods, and Photos
  place.category = Category.find_or_create_by_name("food")

  place.reviews.create(
      :author => "Megan Page",
      :text => "The place is definitely small and intimate but the ambiance is great. If you go, you MUST order the Moqueca (to die for!)...and the bartender serves up some delicious berry mojitos. Its a little on the pricey side, but if you&#39;re looking for a fun night out, this is definitely a place to try.",
      :time => 1364525732,
      :rating => 5.0
  )

  place.reviews.create(
      :author => "Dev Sathe",
      :text => "Lamb skewer I got was good and so was the ceviche. But the service was slow and the food my friends got wasn&#39;t that great.",
      :time => 1369369158,
      :rating => 3.0
  )

  place.periods.create(
      :day => 0,
      :opening_time => 1700,
      :closing_time => 2200
  )
  place.periods.create(
      :day => 1,
      :opening_time => 1100,
      :closing_time => 1430
  )
  place.periods.create(
      :day => 2,
      :opening_time => 1100,
      :closing_time => 1430
  )
  place.periods.create(
      :day => 2,
      :opening_time => 1700,
      :closing_time => 2200
  )
  place.periods.create(
      :day => 3,
      :opening_time => 1100,
      :closing_time => 1430
  )
  place.periods.create(
      :day => 3,
      :opening_time => 1700,
      :closing_time => 2200
  )
  place.periods.create(
      :day => 4,
      :opening_time => 1100,
      :closing_time => 1430
  )
  place.periods.create(
      :day => 4,
      :opening_time => 1700,
      :closing_time => 2200
  )
  place.periods.create(
      :day => 5,
      :opening_time => 1100,
      :closing_time => 1430
  )
  place.periods.create(
      :day => 5,
      :opening_time => 1700,
      :closing_time => 2300
  )
  place.periods.create(
      :day => 6,
      :opening_time => 1700,
      :closing_time => 2300
  )

#-------------------------------------------

  # Create a place
  place = Place.create(
      :permanent_id_num => "44",
      :name => "Fourbarrel Coffee",
      :address => "375 Valencia Street, San Francisco, CA, United States",
      :phone_number => "(415) 252-0800",
      :rating => 4.5,
      :website => "http://www.fourbarrelcoffee.com/",
      :price_level => 1,
      :review_summary => "Roasting, extracting, and serving coffee in a beautiful, analog, ethical, and sexy way.",
      :duration => 1.0
  )

  # Create the associated models: Category, Reviews, Periods, and Photos
  place.category = Category.find_or_create_by_name("food")

  place.reviews.create(
      :author => "Shannon Sweetser",
      :text => "Best coffee place! Tons of bike parking outside, a good amount of space inside for the line to accumulate (and it can) and the coffee is roasted literally feet from where it&#39;s brewed. It doesn&#39;t get any better than that. I adored my mocha which was the perfect drinking temperature. I also treated myself to a fantastic chocolate croissant. Highly recommend taking the coffee roasting tour as well where you&#39;ll learn how the coffee is roasted and the importance of the process to developing flavor in the coffee. Amazing coffee place and would recommend it to anyone for an authentic San Francisco experience. Also, I really appreciate the relationship that Four Barrel builds with it&#39;s farmers. Bonus.",
      :time => 1369005450,
      :rating => 5.0
  )

  place.reviews.create(
      :author => "Marcus Ismael",
      :text => "Anchoring the new wave of hipster takeover in the Valencia area of the Mission, Fourbarrel is an excellent place for more than just coffee, but an excellent atmosphere with a good, art, music and style oriented community. Come enjoy a perfectly brewed espresso for relatively good value and have a seat. The decor is mostly bare, but it gives off a very minimal, industrial vibe that allows one to focus more on the coffee. The back of the establishment is the brewing portion of the cafe itself which makes sitting in the cafe more interesting as you can see the beans crushed just yards away. Come once, come often.",
      :time => 1370723090,
      :rating => 4.5
  )

  place.reviews.create(
      :author => "Rohan Thompson",
      :text => "Fourbarrel is my San Francisco roaster of choice. The small-batch single-origin beans from Blue Bottle are of superior quality, but at double the price they&#39;re hardly my stock beverage. That&#39;s where Fourbarrel meets my needs. Their sourcing and roasting is of an exceptional standard, with the beans working very well with the Yama siphon (my preferred daily brewing method—I reserve the Aeropress for weekends and travel). As for the location itself, it&#39;s a total scene; but that needn&#39;t be a bad thing. Despite an often-lengthy line, the staff are always friendly and cast off none of the expected cooler-than-thou attitude. For a bona fide hipster haunt the staff treat their patrons with consistent charm and never fail to earn a tip... At least from me. I&#39;m also a fan of the location. The art—with a few exceptions—is usually worthy of the walls and I appreciate the woodiness. Lastly, seeing the roaster in action is a treat.",
      :time => 1368744567,
      :rating => 4.5
  )

  place.reviews.create(
      :author => "Joseph White",
      :text => "This is an awesome coffee shop. Great wooden design inside and out that is unique looking given it&#39;s middle-of-SF location. Their espresso is probably some of the best I&#39;ve had. I&#39;m always sure to get at least a cappuccino anytime I&#39;m in the city.",
      :time => 1368690722,
      :rating => 4.0
  )

  place.periods.create(
      :day => 0,
      :opening_time => 700,
      :closing_time => 2000
  )
  place.periods.create(
      :day => 1,
      :opening_time => 700,
      :closing_time => 2000
  )
  place.periods.create(
      :day => 2,
      :opening_time => 700,
      :closing_time => 2000
  )
  place.periods.create(
      :day => 3,
      :opening_time => 700,
      :closing_time => 2000
  )
  place.periods.create(
      :day => 4,
      :opening_time => 700,
      :closing_time => 2000
  )
  place.periods.create(
      :day => 5,
      :opening_time => 700,
      :closing_time => 2000
  )
  place.periods.create(
      :day => 6,
      :opening_time => 700,
      :closing_time => 2000
  )

#-------------------------------------------

  # Create a place
  place = Place.create(
      :permanent_id_num => "45",
      :name => "Sightglass",
      :address => "270 7th Street, San Francisco, CA, United States",
      :phone_number => "(415) 861-1313",
      :rating => 4.5,
      :website => "http://www.sightglasscoffee.com/",
      :price_level => 2,
      :review_summary => "Coffee bar & roastery.",
      :duration => 1.0
  )

  # Create the associated models: Category, Reviews, Periods, and Photos
  place.category = Category.find_or_create_by_name("food")

  place.reviews.create(
      :author => "Rory Carmichael",
      :text => "Good coffee. Neat venue. Basically it&#39;s mildly inferior to the mint square blue bottle, but with more space and a shorter line. It costs a bit more per cup and doesn&#39;t have much in the way of food. Nice alternative if you just want to sit down with a coffee, but if you have the time I&#39;d go to mint square instead.",
      :time => 1356834478,
      :rating => 4.0
  )

  place.reviews.create(
      :author => "Jeremy Meiss",
      :text => "Being a former owner of a coffee shop, I love visiting independent shops whenever/wherever I travel. While in San Francisco I had heard about Sightglass and wanted to check it out. I was not disappointed as the service was excellent, the espresso was competition-grade, and the cappuccino was supurb. The ambiance and decor is unique and really gives the place a good vibe.",
      :time => 1370014847,
      :rating => 5.0
  )

  place.reviews.create(
      :author => "Parth Upadhyay",
      :text => "Really cool shop. Very open feel and the staff is really nice. The coffee is amazing, as well as their hot chocolate.",
      :time => 1371424973,
      :rating => 4.5
  )

  place.periods.create(
      :day => 0,
      :opening_time => 800,
      :closing_time => 1900
  )
  place.periods.create(
      :day => 1,
      :opening_time => 700,
      :closing_time => 1900
  )
  place.periods.create(
      :day => 2,
      :opening_time => 700,
      :closing_time => 1900
  )
  place.periods.create(
      :day => 3,
      :opening_time => 700,
      :closing_time => 1900
  )
  place.periods.create(
      :day => 4,
      :opening_time => 700,
      :closing_time => 1900
  )
  place.periods.create(
      :day => 5,
      :opening_time => 700,
      :closing_time => 1900
  )
  place.periods.create(
      :day => 6,
      :opening_time => 700,
      :closing_time => 1900
  )

#-------------------------------------------

  # Create a place
  place = Place.create(
      :permanent_id_num => "46",
      :name => "Suppenküche",
      :address => "525 Laguna Street, San Francisco, CA, United States",
      :phone_number => "(415) 252-9289",
      :rating => 4.0,
      :website => "http://www.suppenkuche.com/",
      :price_level => 2,
      :review_summary => "A german dining experience in Hayes Valley, San Francisco.",
      :duration => 1.0
  )

  # Create the associated models: Category, Reviews, Periods, and Photos
  place.category = Category.find_or_create_by_name("food")

  place.reviews.create(
      :author => "Katie Stoyka",
      :text => "The fact is that despite the perpetually long wait, this really is great food. And an astounding beer selection. The issue is the volume inside, which can reach speed metal concert proportions. Come early on a weekday if you&#39;d like to hear anything your table-mates are saying.",
      :time => 1367648300,
      :rating => 4.0
  )

  place.reviews.create(
      :author => "Evan Kaverman",
      :text => "As one of the busiest restaurants in the city, it can be impossible to get in, but it is well worth the wait - and really, by the time you finish 1.5 liters of beer... your table will be ready. Food is simple, German fare, without too much flair. Haven&#39;t found anywhere else I can get real red cabbage and spaetzle though.",
      :time => 1370200587,
      :rating => 5.0
  )

  place.reviews.create(
      :author => "Jerome Fried",
      :text => "Ready to head to Germany? That&#39;s what you get at this SF hidden gem. Very little signage tells you it&#39;s a neighborhood secret, but once you get inside, it&#39;s CLEARLY no secret. German-style bierhaus, complete with bench seating. The food is BEYOND good, and the service is commensurate. Great for groups, but be prepared for a LOUD dining experience. Oh yeah, I almost forgot... THEY SERVE BEER IN *FIVE* LITER BOOTS",
      :time => 1367432395,
      :rating => 3.0
  )

  place.reviews.create(
      :author => "justin son",
      :text => "When i first walked into suppenkuche, I got immediately aggravated because I thought I was going to have soup for dinner. I was wrong. The pork sausage was delightful and the mashed potatoes were divine. Go there not during lunch and dinner hours because it can get crazy and crowded.",
      :time => 1370191062,
      :rating => 4.0
  )

  (0..6).each do |day|
    place.periods.create(
        :day => day,
        :opening_time => 1700,
        :closing_time => 2200
    )
  end

#-------------------------------------------

  # Create a place
  place = Place.create(
      :permanent_id_num => "47",
      :name => "Dottie's",
      :address => "28 6th Street, San Francisco, CA, United States",
      :phone_number => "(415) 885-2767",
      :rating => 4.5,
      :website => "http://dotties.biz/",
      :price_level => 2,
      :review_summary => "Specializing in house-made breads and pastries with dishes such as Black Bean Cakes and Eggs, and Lamb-Merguez, roasted garlic, tomato, spinach and goat cheese omelet.",
      :duration => 1.0
  )

  # Create the associated models: Category, Reviews, Periods, and Photos
  place.category = Category.find_or_create_by_name("food")

  place.reviews.create(
      :author => "Adam Lasnik",
      :text => "My friends and I enjoyed our food: well-seasoned, nicely cooked, and generously portioned. The cornbread was different than your typical cornbread, but quite tasty! With that said, I didn&#39;t find any of the food to be outstanding, and I was a bit gobsmacked that we were charged for the jelly (that I assumed just came with the cornbread). Nickel and diming like that just seems silly and petty and dampens an otherwise fine meal... especially when the brunch itself is a bit on the pricey side. Another downside: the area is rather sketchy; wouldn&#39;t recommend parking an expensive car here, for instance :\. On the brighter side: our wait (for three people on a weekend) wasn&#39;t that long, and our server was cheerful and helpful.",
      :time => 1369443797,
      :rating => 5.0
  )

  place.reviews.create(
      :author => "Ade Oshineye",
      :text => "The good: - the food is very excellent - the menu is comprehensive and varied - the prices are reasonable - the portions are massive - once you&#39;ve made your order the food turns up very quickly. The bad: - there&#39;s no wifi - the neighbourhood is unpleasant - the queue is epic. I got there 10 minutes after opening time (7.39 on a Saturday morning) and had to wait a few minutes to be seated. People who get there any later than that should bring a book to read. - if you make the mistake of sitting facing the queue you&#39;ll feel guilty and rush your meal. You should try Dottie&#39;s at least once but Honey Honey is an equivalent experience a few blocks away without the epic queue and unpleasant neighbourhood.",
      :time => 1368907547,
      :rating => 4.0
  )

  place.periods.create(
      :day => 0,
      :opening_time => 730,
      :closing_time => 1600
  )
  place.periods.create(
      :day => 1,
      :opening_time => 730,
      :closing_time => 1500
  )
  place.periods.create(
      :day => 4,
      :opening_time => 730,
      :closing_time => 1500
  )
  place.periods.create(
      :day => 5,
      :opening_time => 730,
      :closing_time => 1500
  )
  place.periods.create(
      :day => 6,
      :opening_time => 730,
      :closing_time => 1600
  )

#-------------------------------------------

  # Create a place
  place = Place.create(
      :permanent_id_num => "48",
      :name => "Limón Rotisserie",
      :address => "524 Valencia Street, San Francisco, CA, United States",
      :phone_number => "(415) 252-0918",
      :rating => 4.0,
      :website => "http://www.limon-sf.com/",
      :price_level => 2,
      :review_summary => "The ambiance is as energetic as its menu, featuring an upscale setting with a modern flare. The bright colors represent a quintessential Peruvian hue while the Latin lounge music engages you soul to c",
      :duration => 1.0
  )

  # Create the associated models: Category, Reviews, Periods, and Photos
  place.category = Category.find_or_create_by_name("food")

  place.reviews.create(
      :author => "Greg Wright",
      :text => "The roast chicken is what this place is known for. Roast chicken is a fairly common dish, but Limon does it exceptionally well. It is tender and seasoned extremely well. If you are with a large group splitting a half or whole chicken is the way to go",
      :time => 1371250435,
      :rating => 5.0
  )

  place.reviews.create(
      :author => "Mindy Cheung",
      :text => "Scored a table with no-wait on Saturday for dinner! The food and staff was great. We were seated upstairs in the loft so no much of a decor. For a matter of fact, I actually had to flag down a staff to fix our seesawing table because the drinks we had on the table were moving too much. Everything else was great for the remaining of the evening. Drinks and a very delicious and filling dinner came to $30/person tips and tax included. I&#39;m already looking forward to coming back here again!",
      :time => 1369937926,
      :rating => 3.0
  )

  place.reviews.create(
      :author => "Ab Villanueva",
      :text => "Excellent rotisserie chicken and &quot;lomito&quot; saltado. Sangria was pretty nice. I was brought by a Peruvian friend who highly recommends the place as it is his favorite local restaurant, he swears by the salsas which in his opinion are pretty authentic.",
      :time => 1362414692,
      :rating => 4.0
  )

  place.reviews.create(
      :author => "Zarah Ahmed",
      :text => "Sangria sangria sangria! Such a unique delish place to go! Place i would take my friends who are here coming to visit SF! First time trying peruvian food, and completely fell in love! Their appetizers aloned filled us up. Great place to order multiple things and share family style by nibbling on all the diff things. NEver thought id like red beets but it was so tasty!",
      :time => 1362362049,
      :rating => 4.0
  )

  place.periods.create(
      :day => 0,
      :opening_time => 1200,
      :closing_time => 2000
  )
  place.periods.create(
      :day => 1,
      :opening_time => 1200,
      :closing_time => 2230
  )
  place.periods.create(
      :day => 2,
      :opening_time => 1200,
      :closing_time => 2230
  )
  place.periods.create(
      :day => 3,
      :opening_time => 1200,
      :closing_time => 2230
  )
  place.periods.create(
      :day => 4,
      :opening_time => 1200,
      :closing_time => 2230
  )
  place.periods.create(
      :day => 5,
      :opening_time => 1200,
      :closing_time => 2300
  )
  place.periods.create(
      :day => 6,
      :opening_time => 1200,
      :closing_time => 2300
  )

#---------------------- NIGHTLIFE ---------------------

  # Create a place
  place = Place.create(
      :permanent_id_num => "61",
      :name => "DNA Lounge",
      :address => "375 Eleventh St., San Francisco, CA, United States",
      :phone_number => "(415) 626-1409",
      :rating => 4.0,
      :website => "http://www.dnalounge.com",
      :price_level => 2,
      :review_summary => "A late-night, all ages nightclub featuring live music, DJ dancing, burlesque, etc. Regular events include Bootie, Blow Up, Trannyshack, Death Guild, Hubba Hubba Revue, and Bohemian Carnival.",
      :duration => 2.0
  )

  # Create the associated models: Category, Reviews, Periods, and Photos
  place.category = Category.find_or_create_by_name("nightlife")

  place.reviews.create(
      :author => "Mary Nguyen",
      :text => "Music depends on the DJ. I like their mission of mashing oldies and top 40s tho. Drinks are good but it is omg-status super super crowded though. And it doesn&#39;t matter what you wear. Have fun!",
      :time => 1363924920,
      :rating => 5.0
  )

  place.reviews.create(
      :author => "Winnie Fung",
      :text => "This place is small, so it gets crowded. But the crowds are always laid back and fun to party with. The DJ&#39;s are super cool and play good music. I would recommend coming to this place if you want to have a chill night with your friends.",
      :time => 1362426200,
      :rating => 3.0
  )

  place.reviews.create(
      :author => "Jesse Jesusson",
      :text => "I come here regularly on Saturday nights for &quot;Booty&quot;, a top 40 mash-up night event. I LOVE it because I get to sing and dance to all my guilty pleasures. Drinks are moderately priced and can be strong depending on what you order. It ultimately depends on what bartender waits on you. There are two different rooms with distinct music. The smaller room upstairs has electronic/trance music AND it has a bar. There is also a ton of seating space upstairs and a bar that is way less crowded than the downstairs. The main dancing room is complete with a dancing stage. A really cool feature about this place is that there is a food bar upstairs AND it is directly connected to a pizza parlor downstairs that stays open AFTER the club closes down. I totally recommend going, however, parking around the area is a little sketchy so cabbing or public transit might be a better option.",
      :time => 1364319815,
      :rating => 4.0
  )

  place.reviews.create(
      :author => "curtis lai",
      :text => "Went here for an event. the dance floor was pretty small but just big enough. its a bit of a maze. a bar up and down stairs. sound system was loud.",
      :time => 1370732533,
      :rating => 4.0
  )

  (0..6).each do |day|
    place.periods.create(
        :day => day,
        :opening_time => 2100,
        :closing_time => 0
    )
  end

#-------------------------------------------

  # Create a place
  place = Place.create(
      :permanent_id_num => "62",
      :name => "Bimbo's 365 Club",
      :address => "1025 Columbus Avenue, San Francisco, CA, United States",
      :phone_number => "(415) 474-0365",
      :rating => 4.0,
      :website => "http://www.bimbos365club.com/",
      :price_level => 3,
      :review_summary => "San Franciscoâs favorite nightspot for over 80 years! Offering the best in live music and private events. Family owned and operated since 1931.",
      :duration => 2.0
  )

  # Create the associated models: Category, Reviews, Periods, and Photos
  place.category = Category.find_or_create_by_name("nightlife")

  place.reviews.create(
      :author => "Tim McAndrew",
      :text => "I recently moved to San Francisco from Washington DC, I can honestly say that when I went to Bimbos was the first time I thought to myself &quot;I&#39;m home&quot;. Walking in the front door you travel back to a time when every thing was elegant and independent. From the decor of the venue, I thought for a second that I was going to see the Rat Pack, instead of Texas is the Reason. The bartenders were in shirt and tie, and the entire place was draped in red velvet drapes. Cash bar, sit down dinning options and a pretty large concert space. I hope to see many, many more shows here.",
      :time => 1364846700,
      :rating => 5.0
  )

  place.reviews.create(
      :author => "Daniel Suarez",
      :text => "Really nice old school decoration, as on my father&#39;s days! Great acoustic and music, i enjoyed about 2 hours. The drinks are regular, but you can&#39;t have it all, do you?",
      :time => 1362446641,
      :rating => 3.0
  )

  place.reviews.create(
      :author => "Jay A",
      :text => "I love how classy this venue is. It&#39;s like stepping into an old 50&#39;s movie. When I went to see Mayer Hawthorne, there was a 2 drink limit. Parking is a hassle in this area, so if you&#39;re coming to see a band or performer, be sure to come early.",
      :time => 1370720387,
      :rating => 4.0
  )

  (0..6).each do |day|
    place.periods.create(
        :day => day,
        :opening_time => 2100,
        :closing_time => 0
    )
  end

#-------------------------------------------

  # Create a place
  place = Place.create(
      :permanent_id_num => "63",
      :name => "Freight & Salvage Coffeehouse",
      :address => "2020 Addison Street, Berkeley, CA, United States",
      :phone_number => "(510) 644-2020",
      :rating => 4.5,
      :website => "http://www.thefreight.org/",
      :price_level => 2,
      :review_summary => "Freight & Salvage Coffeehouse, a nonprofit community arts organization, promotes traditional music for all ages through performances, classes, and community gatherings.",
      :duration => 2.0
  )

  # Create the associated models: Category, Reviews, Periods, and Photos
  place.category = Category.find_or_create_by_name("nightlife")

  place.reviews.create(
      :author => "Phil Morton",
      :text => "Sumptuous sound system! There&#39;s a bit of space to dance, which sometimes happens.",
      :time => 1358959866,
      :rating => 5.0
  )

  place.reviews.create(
      :author => "Adam Lasnik",
      :text => "[from Sep 2006] Great ecclectic set of talented artists, friendly crew, fine sound system. Okay, so it doesn&#39;t have a very intimate feel (I agree with the &quot;barn&quot; description of another poster), and the chairs feel like, well, folding chairs. And yeah, there&#39;s no alcohol sold but, sheesh people, must y&#39;all drink *every time* you go out? Have a coffee or juice fer cryin&#39; out loud and just enjoy a natural mellow without the booze and whine, eh? ;) Other stuff: easy parking, reasonable ticket prices, not far from the freeway if I remember correctly and not too hard to get to via public transit.",
      :time => 1289972991,
      :rating => 4.0
  )

  place.periods.create(
      :day => 0,
      :opening_time => 1200,
      :closing_time => 1700
  )
  place.periods.create(
      :day => 0,
      :opening_time => 2000,
      :closing_time => 2200
  )
  place.periods.create(
      :day => 1,
      :opening_time => 1200,
      :closing_time => 1700
  )
  place.periods.create(
      :day => 1,
      :opening_time => 2000,
      :closing_time => 2200
  )
  place.periods.create(
      :day => 2,
      :opening_time => 1200,
      :closing_time => 1700
  )
  place.periods.create(
      :day => 2,
      :opening_time => 2000,
      :closing_time => 2200
  )
  place.periods.create(
      :day => 3,
      :opening_time => 1200,
      :closing_time => 1700
  )
  place.periods.create(
      :day => 3,
      :opening_time => 2000,
      :closing_time => 2200
  )
  place.periods.create(
      :day => 4,
      :opening_time => 1200,
      :closing_time => 1700
  )
  place.periods.create(
      :day => 4,
      :opening_time => 2000,
      :closing_time => 2200
  )
  place.periods.create(
      :day => 5,
      :opening_time => 1200,
      :closing_time => 1700
  )
  place.periods.create(
      :day => 5,
      :opening_time => 2000,
      :closing_time => 2200
  )
  place.periods.create(
      :day => 6,
      :opening_time => 1200,
      :closing_time => 1700
  )
  place.periods.create(
      :day => 6,
      :opening_time => 2000,
      :closing_time => 2200
  )

#-------------------------------------------

  # Create a place
  place = Place.create(
      :permanent_id_num => "64",
      :name => "MatrixFillmore",
      :address => "3138 Fillmore Street, San Francisco, CA, United States",
      :phone_number => "(415) 563-4180",
      :rating => 4.0,
      :website => "http://www.matrixfillmore.com/",
      :price_level => 3,
      :review_summary => "Matrix Fillmore is one of San Francisco's favorite destinations for weekly events featuring DJs. We are perfect for private events and catering as well.",
      :duration => 2.0
  )

  # Create the associated models: Category, Reviews, Periods, and Photos
  place.category = Category.find_or_create_by_name("nightlife")

  place.reviews.create(
      :author => "justin son",
      :text => "Matrix Fillmore is one of the anchor bars of the Blue Triangle nightlife area of SF. Matrix usually gets packed with a line of people who are ready to drink and party till 2am. On a good night it can be fun. But it can get so crowded that you end up sweating like crazy because Matrix has a gas powered fire place. The drinks are so so and the bar tenders can be rude. As for hooking up, it&#39;s up to you and your &quot;game&quot;.",
      :time => 1370211791,
      :rating => 4.0
  )

  place.reviews.create(
      :author => "Chiaki Osaka",
      :text => "I love the music at matrix on the weekends. They definitely do a good job on selecting good djs with excellent talents. EDM is super big there as well. People dress classy and the best part of the night....you can simply walk over to piza orgasmica for a drunk munchie",
      :time => 1364006540,
      :rating => 4.0
  )

  place.periods.create(
      :day => 0,
      :opening_time => 2100,
      :closing_time => 200
  )
  place.periods.create(
      :day => 1,
      :opening_time => 2100,
      :closing_time => 200
  )
  place.periods.create(
      :day => 3,
      :opening_time => 2100,
      :closing_time => 200
  )
  place.periods.create(
      :day => 4,
      :opening_time => 2100,
      :closing_time => 200
  )
  place.periods.create(
      :day => 5,
      :opening_time => 2000,
      :closing_time => 200
  )
  place.periods.create(
      :day => 6,
      :opening_time => 2000,
      :closing_time => 200
  )

#-------------------------------------------

  # Create a place
  place = Place.create(
      :permanent_id_num => "65",
      :name => "The Endup",
      :address => "401 6th Street, San Francisco, CA, United States",
      :phone_number => "(415) 896-1075",
      :rating => 4.0,
      :website => "http://www.theendup.com/",
      :price_level => 2,
      :review_summary => "The longest running nightclub in San Francisco, serving the best music since 1973.",
      :duration => 2.0
  )

  # Create the associated models: Category, Reviews, Periods, and Photos
  place.category = Category.find_or_create_by_name("nightlife")

  place.reviews.create(
      :author => "Elijah Wolfe",
      :text => "now the music is awsome if you like men with no shirts this is the club for you. now sat-sun they are open 24hours the cost is 20$ but they have a outside part with a walk up balcony and some of the best mix drinks i have had. p.s try not to pass out or they will ask you to leave very fun though",
      :time => 1364258381,
      :rating => 5.0
  )

  place.reviews.create(
      :author => "Careyokke Hargono",
      :text => "THEY NEVER CLOSEEEEEE... if u want an after party... go to the endup everyone goes there... sometime they even have food inside... affordable drinks and nice music",
      :time => 1364253603,
      :rating => 3.0
  )

  place.reviews.create(
      :author => "Paul Romero",
      :text => "The coolest after hours hand out and place to meet up with friends. This is for the hardcore part goers who like to enjoy the entirety of their weekends. Among other things one can find many of the locals here to meet up with and make friends in this scene. A cool place.",
      :time => 1364425167,
      :rating => 4.0
  )

  place.reviews.create(
      :author => "Dave Tada",
      :text => "As the name implies, this is where everyone ends up after all the regular bars close. They always bring in great deep house djs and there&#39;s always a chill but fun crowd",
      :time => 1372539347,
      :rating => 4.0
  )

  (0..6).each do |day|
    place.periods.create(
        :day => day,
        :opening_time => 2000,
        :closing_time => 500
    )
  end

#-------------------------------------------

  # Create a place
  place = Place.create(
      :permanent_id_num => "66",
      :name => "The Uptown Nightclub",
      :address => "1928 Telegraph Avenue, Oakland, CA, United States",
      :phone_number => "(510) 451-8100",
      :rating => 3.5,
      :website => "http://www.uptownnightclub.com/",
      :price_level => 0,
      :review_summary => "Celebration the Golden Age of Oakland. Bringing National and International acts while supporting local Artists and Musicians. Burlesque every Monday, Free Live Music every Wednesday.",
      :duration => 2.0
  )

  # Create the associated models: Category, Reviews, Periods, and Photos
  place.category = Category.find_or_create_by_name("nightlife")

  place.reviews.create(
      :author => "Brian Pepin",
      :text => "Good, cheap place to see music, although the bands are pretty hit-or-miss.",
      :time => 1292622446,
      :rating => 4.0
  )

  place.reviews.create(
      :author => "Dixon C.",
      :text => "Awesome place! Huge dance floor in the main room. Great music and atmosphere! The employees are the best. The people that i have met that work were very friendly. Weekends this is the place to be had a great time.",
      :time => 1326947811,
      :rating => 3.0
  )

  (0..6).each do |day|
    place.periods.create(
        :day => day,
        :opening_time => 2000,
        :closing_time => 200
    )
  end

#-------------------------------------------

  # Create a place
  place = Place.create(
      :permanent_id_num => "67",
      :name => "El Rio",
      :address => "3158 Mission Street, San Francisco, CA, United States",
      :phone_number => "(415) 282-3325",
      :rating => 4.0,
      :website => "http://www.elriosf.com/",
      :price_level => 2,
      :review_summary => "Est 1978-Queerish Dive Bar in the Mission/Bernal. Huge Garden/Patio, Live Music, DJ Parties, Film, Bloody Marty Bar, Espresso. All good and friendly folks are welcome!",
      :duration => 2.0
  )

  # Create the associated models: Category, Reviews, Periods, and Photos
  place.category = Category.find_or_create_by_name("nightlife")

  place.reviews.create(
      :author => "April G",
      :text => "I love the back patio! This is the perfect place to come on a sunny day and just chill with friends and a beer. The bartenders are attentive and they have great events and happy hours every night of the week!",
      :time => 1368917429,
      :rating => 5.0
  )

  place.reviews.create(
      :author => "Dee Tran",
      :text => "You should definitely come here during their &quot;mango&quot; events. It&#39;s a daytime party that they have once a month. Chill vibe and plenty of eye candy.They also make fantastic margaritas and will have to come back for their $1 oysters on Friday nights.",
      :time => 1371527452,
      :rating => 3.0
  )

  place.reviews.create(
      :author => "Edward Muna",
      :text => "El Rio is a great bar with a friendly staff. They have a variety of events here weekly. It is also a bay that has a primarily lgbt clientele. They sell indian tacos as well. The drinks are pretty affordable and the atmosphere is very chill and friendly.",
      :time => 1368917880,
      :rating => 4.0
  )

  place.reviews.create(
      :author => "Carter Gibson",
      :text => "What at first appears to be a small dive bar opens up into a huge establishment with a fantastic patio (equipped with heat lamps) and concert venue. There are no less than four places to order beers on a busy night and the crowd is always relaxed and friendly (unless there&#39;s a punk show). This place is a favorite and somewhere I don&#39;t regret having spent as much time and money as I have.",
      :time => 1358993661,
      :rating => 4.0
  )

  (0..6).each do |day|
    place.periods.create(
        :day => day,
        :opening_time => 1300,
        :closing_time => 200
    )
  end

#-------------------------------------------

  # Create a place
  place = Place.create(
      :permanent_id_num => "68",
      :name => "Smuggler's Cove",
      :address => "650 Gough Street, San Francisco, CA, United States",
      :phone_number => "(415) 869-1900",
      :rating => 4.5,
      :website => "http://www.smugglerscovesf.com/",
      :price_level => 3,
      :review_summary => "Smuggler's Cove is a rum & tiki bar featuring the largest selection of premium rums in the United States. We also feature over 70 vintage cocktails made with fresh & housemade ingredients. Smuggler's Cove was named to Esquire Magazine's list of America's Best Bars in 2013, Top 50 Bars in the World by the Times of London, and won North American Cocktail Lounge of the Year at the 2011 Nightclub and Bar Show.",
      :duration => 2.0
  )

  # Create the associated models: Category, Reviews, Periods, and Photos
  place.category = Category.find_or_create_by_name("nightlife")

  place.reviews.create(
      :author => "Daisy Chavez",
      :text => "Smugglers cove is the best place to go on the weekend if you want tasty drinks and great service. The outside looks very discrete so be sure you don&#39;t miss it. As soon as you walk in your in the midst of a pirate ship. Be sure to get there early because it fills up quick. Be sure not to burn your eyebrows when you order a group drink. Grab a table for those as they are on fire!",
      :time => 1364169067,
      :rating => 5.0
  )

  place.reviews.create(
      :author => "Jasper Lin",
      :text => "I&#39;ve been obsessed with rum since meeting my wife, who is from Trinidad. This place has a great collection of rum, some of which you cannot find very easily. On top of that, their mixed drinks are quite good and strong, especially the ones that sport a warning to the effect of: drink these at your own risk. Still, you won&#39;t regret trying them out based on their taste, but you might regret based on the consequences. They&#39;re the type of drinks that sneak up on you. You&#39;re having a great time and completely in control for one minute, then the next you&#39;re under the table, fetal position, trying to figure out if the whole bar is actually a giant roller coaster car doing loops on the track. It&#39;s quite fun.",
      :time => 1372020389,
      :rating => 4.0
  )

  (0..6).each do |day|
    place.periods.create(
        :day => day,
        :opening_time => 1700,
        :closing_time => 115
    )
  end

#-------------------------------------------

  # Create a place
  place = Place.create(
      :permanent_id_num => "69",
      :name => "Bossa Nova",
      :address => "139 8th Street, San Francisco, CA, United States",
      :phone_number => "(415) 558-8004",
      :rating => 4.0,
      :website => "http://www.bossahome.com/",
      :price_level => 1,
      :review_summary => "Created with the look and feel of the Favela, Bossa Nova SF brings you the flavor of Rio's Streets to San Francisco. The Favela (Rio's vibrant ghetto culture)is the birthplace of Bossa Nova music.",
      :duration => 2.0
  )

  # Create the associated models: Category, Reviews, Periods, and Photos
  place.category = Category.find_or_create_by_name("nightlife")

  place.reviews.create(
      :author => "Megan Page",
      :text => "The place is definitely small and intimate but the ambiance is great. If you go, you MUST order the Moqueca (to die for!)...and the bartender serves up some delicious berry mojitos. Its a little on the pricey side, but if you&#39;re looking for a fun night out, this is definitely a place to try.",
      :time => 1364525732,
      :rating => 5.0
  )

  place.reviews.create(
      :author => "Dev Sathe",
      :text => "Lamb skewer I got was good and so was the ceviche. But the service was slow and the food my friends got wasn&#39;t that great.",
      :time => 1369369158,
      :rating => 3.0
  )

  place.reviews.create(
      :author => "Wine Traveler",
      :text => "The food was amazing and so reasonably priced. Way more food than I expected.",
      :time => 1363052066,
      :rating => 4.0
  )

  place.reviews.create(
      :author => "Sam Blitzstein",
      :text => "The grilled salmon fillet was amazing, and they have great assorted fruit mojitos.",
      :time => 1368324173,
      :rating => 4.0
  )

  place.periods.create(
      :day => 0,
      :opening_time => 1700,
      :closing_time => 2200
  )
  place.periods.create(
      :day => 1,
      :opening_time => 1100,
      :closing_time => 1430
  )
  place.periods.create(
      :day => 2,
      :opening_time => 1100,
      :closing_time => 1430
  )
  place.periods.create(
      :day => 2,
      :opening_time => 1700,
      :closing_time => 2200
  )
  place.periods.create(
      :day => 3,
      :opening_time => 1100,
      :closing_time => 1430
  )
  place.periods.create(
      :day => 3,
      :opening_time => 1700,
      :closing_time => 2200
  )
  place.periods.create(
      :day => 4,
      :opening_time => 1100,
      :closing_time => 1430
  )
  place.periods.create(
      :day => 4,
      :opening_time => 1700,
      :closing_time => 2200
  )
  place.periods.create(
      :day => 5,
      :opening_time => 1100,
      :closing_time => 1430
  )
  place.periods.create(
      :day => 5,
      :opening_time => 1700,
      :closing_time => 2300
  )
  place.periods.create(
      :day => 6,
      :opening_time => 1700,
      :closing_time => 2300
  )

#-------------------------------------------

  # Create a place
  place = Place.create(
      :permanent_id_num => "70",
      :name => "Temple Nightclub",
      :address => "540 Howard Street, San Francisco, California, United States",
      :phone_number => "(415) 978-9942",
      :rating => 4.0,
      :website => "http://www.templesf.com/",
      :price_level => 3,
      :review_summary => "Temple Night Club is both a sushi restaurant and dance club offering the best live music venue in San Francisco. Ask about our corporate event and party space rental!",
      :duration => 2.0
  )

  # Create the associated models: Category, Reviews, Periods, and Photos
  place.category = Category.find_or_create_by_name("nightlife")

  place.reviews.create(
      :author => "Winnie Fung",
      :text => "This club is huge, there are 2 levels, top floor plays house music and level floor usually plays top 40&#39;s. I like staying downstairs because it&#39;s music popping and the crowd are usually more fun. I usually get one strong drink here and then I&#39;m ready to have a ball. The staff are always super friendly and outgoing. I love the decor here, it&#39;s like a temple, with the buddah decor.",
      :time => 1362425937,
      :rating => 5.0
  )

  place.reviews.create(
      :author => "Mark Cordero",
      :text => "If you like hip-hop and top 40 &amp; house music, they got &#39;em here with two floors different genres, just vibing out is pretty cool and fun here. As a street dancer, there&#39;s open cyphers here and there if you want to get down Fridays and it&#39;s pretty dope. Drinks a little pricey in my opinion, but shouldn&#39;t stop you from having a good time. Thats it. peace",
      :time => 1370734934,
      :rating => 3.0
  )

  place.periods.create(
      :day => 5,
      :opening_time => 2200,
      :closing_time => 400
  )
  place.periods.create(
      :day => 6,
      :opening_time => 2200,
      :closing_time => 400
  )


#-------------------------------------------

# Create a place
  place = Place.create(
      :permanent_id_num => "71",
      :name => "Zeitgeist",
      :address => "199 Valencia Street, San Francisco, CA, United States",
      :phone_number => "(415) 255-7505",
      :rating => 4.0,
      :website => "http://www.zeitgeistsf.com/",
      :price_level => 1,
      :review_summary => "Full bar, beer garden, grill and games room. Warm Beer and Cold Women.",
      :duration => 1.0
  )

# Create the associated models: Category, Reviews, Periods, and Photos
  place.category = Category.find_or_create_by_name("nightlife")

  place.reviews.create(
      :author => "Brian Reichholf",
      :text => "Fantastic bar and a nice choice of quick burgers. Also, great beer garden. One of my top places to grab a beer in SF.",
      :time => 1370891617,
      :rating => 5.0
  )

  place.reviews.create(
      :author => "Sasa RA",
      :text => "I went to a great hat shop in San Francisco and the lady attending the store gave me a great tip: &quot;go to Zeitgeist&quot;. Cool vibes. Great people. And an awesome beer garden.",
      :time => 1371341559,
      :rating => 3.0
  )

  place.reviews.create(
      :author => "Sandeep Sheoran",
      :text => "one of the places in sf, with cheap beer and nice ambience, can smoke outside nice bunch of peeps and stiff drinks",
      :time => 1372615394,
      :rating => 4.0
  )

  (0..6).each do |day|
    place.periods.create(
        :day => day,
        :opening_time => 900,
        :closing_time => 200
    )
  end


#---------------------- SPORTS ---------------------


  # Create a place
  place = Place.create(
      :permanent_id_num => "81",
      :name => "The Olympic Club",
      :address => "599 Skyline Blvd, San Francisco, CA, United States",
      :phone_number => "(415) 404-4300",
      :rating => 4.5,
      :website => "http://www.olyclub.com/",
      :price_level => 0,
      :review_summary => "Established in 1860 in San Francisco & dedicated to the pursuit of amateur athletic excellence, The Olympic Club enjoys the distinction of being America's oldest athletic club. The objects and purposes of the Club are to promote physical culture, social intercourse and the fostering of amateur athletics in a spirit of close harmony among the membership. Comprised of more than 5,000 active members & with historic clubhouses located in downtown San Francisco & overlooking the Pacific Ocean, Club members regularly participate in athletic & social events wearing the Club's internationally recognized 'Winged O'. The Club built the City Clubhouse in 1912, after the 1906 earthquake and fire destroyed the original building, and it was restored in 2006 to its original glory. The clubhouse features a fitness center, cardio solarium, hotel facilities, handball and squash courts, circuit training facilities, two basketball courts and two swimming pools. In 1918, the Club assumed operations of the Lakeside Golf Club, including an 18-hole golf course. By 1922, the Club had acquired enough acreage to replace the original golf course with two 18-hole golf courses. Famed architect Arthur Brown, designer of the San Francisco City Hall, designed the Lakeside clubhouse, which officially opened in 1925. The clubhouse features spectacular dining and banquet facilities, meeting rooms, locker rooms, an exercise center, massage services and a swimming pool. The Golf Shop was completely renovated in spring 2011. Willie Watson and course superintendent Sam Whiting designed the first Lake and Ocean courses in 1924. Unfortunately, storm damage led Sam Whiting to redesign both courses again in 1927. The Lake Course remains true to the 1927 design with minimal renovations in the intervening years. Prior to the 1955 U.S. Open, the Club brought the USGAâs official course architect, Robert Trent Jones, Sr., to toughen the Lake Course for competition. Most recently, the Club completed the Lake Course Greens Replacement project. Conversion from poa annua to bent-grass greens was the primary objective of the project, but the crew also rebuilt and renovated greens. The new 8th hole, the first routing change to the course since 1927, was sculpted into the surrounding hillside with views of the clubhouse. It plays as a 200-yard par 3. Additional alterations were done for the 2012 U.S. Open Championship.",
      :duration => 3.0
  )

  # Create the associated models: Category, Reviews, Periods, and Photos
  place.category = Category.find_or_create_by_name("sports")

  place.reviews.create(
      :author => "Chin Lau",
      :text => "This place is good to learn how to practice your golf skills.",
      :time => 1362165635,
      :rating => 5.0
  )

  place.reviews.create(
      :author => "George D",
      :text => "Great course. Just love drubbing Greg there.",
      :time => 1364003799,
      :rating => 4.0
  )

  (0..6).each do |day|
    place.periods.create(
        :day => day,
        :opening_time => 600,
        :closing_time => 2200
    )
  end

#-------------------------------------------

  # Create a place
  place = Place.create(
      :permanent_id_num => "82",
      :name => "Golden Gate Fields",
      :address => "1100 Eastshore Highway, Berkeley, CA, United States",
      :phone_number => "(510) 559-7300",
      :rating => 4.5,
      :website => "http://www.goldengatefields.com/",
      :price_level => 0,
      :review_summary => "Northern Californiaâs premier destination for horse racing and horse racing results. Located right along the San Francisco Bay in Berkeley, fans are treated to live horse racing.",
      :duration => 3.0
  )

  # Create the associated models: Category, Reviews, Periods, and Photos
  place.category = Category.find_or_create_by_name("sports")

  place.reviews.create(
      :author => "Dee M",
      :text => "We had a great time. Fun and unique thing to do on the weekend.",
      :time => 1370824793,
      :rating => 5.0
  )

  place.reviews.create(
      :author => "Fran V",
      :text => "Ever since Bay Meadows in San Mateo closed, I&#39;ve been wanting to tryout this place. When I finally went last Sunday with my family, I was pretty happy. Driving there was pretty easy. Took the Buchanan exit and then followed the racetrack signs. Parked in the valet lot ($8) and then entered into the Turf Club area for brunch. To my surprise, the Turf Club area was big. I was with some family members so we decided to take on the buffet. Usually it cost $25/person for buffet at the Turf Club, but we were only charged $19 because it was Dollar Sundays. We got to enjoy brunch and a great view of the races from a window table. What was also great was to have a small tv at our table so we could watch other simulcasts. Also, the day that I went they were celebrating Chinese New Year so ever person that entered got a red envelope with a voucher that had a surprise amount. When it was scanned, the voucher only had $2! Oh well. Beside the special giveaway, they also had some special entertainment to celebrate Chinese New Year. It was all around a fun day at the track. Note about valet parking: It was very unorganized and chaotic when we tried to pick up our car from the valet. When we arrived curbside, we joined a sea of people trying to find an attendant to pass on the voucher to. We waited about 15 minutes for our car to be pulled up.",
      :time => 1341425336,
      :rating => 4.0
  )

  place.reviews.create(
      :author => "michael randolph",
      :text => "oldest sport is still fun people really dressing up drinking bubbles",
      :time => 1357753429,
      :rating => 4.0
  )

  place.reviews.create(
      :author => "Dragoslav Grbovic",
      :text => "Easy access, great view of the bay and golden gate bridge. Good amenities.",
      :time => 1296324079,
      :rating => 5.0
  )

  (0..6).each do |day|
    place.periods.create(
        :day => day,
        :opening_time => 1000,
        :closing_time => 1700
    )
  end

#-------------------------------------------

  # Create a place
  place = Place.create(
      :permanent_id_num => "83",
      :name => "Presidio Golf Course",
      :address => "300 Finley Road, San Francisco, CA, United States",
      :phone_number => "(415) 561-4653",
      :rating => 4.0,
      :website => "http://www.presidiogolf.com/",
      :price_level => 0,
      :review_summary => "The Presidio, located just minutes from downtown San Francisco, plays 6,500 yards and winds through beautiful Eucalyptus and Monterey Pine trees in The City's trademark hills.",
      :duration => 3.0
  )

  # Create the associated models: Category, Reviews, Periods, and Photos
  place.category = Category.find_or_create_by_name("sports")

  place.reviews.create(
      :author => "Matt Stevenson",
      :text => "Great public course as close to a major city as one can possibly be. Super twilight rates plus two free beers is hard to top.",
      :time => 1370208954,
      :rating => 4.0
  )

  place.reviews.create(
      :author => "Nolan Griggs",
      :text => "Paid 160 bucs today for unfriendly staff and ROCK SOLID GRAVEL bunkers. worst on the entire peninsula. I started picking my ball up and taking a drop so I wouldn&#39;t ruin my clubs by hitting it out of the adobe bunkers. I want some of my money back, but I&#39;m not about to be that guy. Overall, it was a great course to play on a nice day, but NOT worth the $$.",
      :time => 1339916763,
      :rating => 3.0
  )

  place.reviews.create(
      :author => "Ben Crowell",
      :text => "Course is in very good shape and a solid value for SF residents. Probably too pricey relative to quality if you&#39;re not at least from the Bay Area, but I love playing here.",
      :time => 1341030149,
      :rating => 5.0
  )

  place.reviews.create(
      :author => "Leake Little",
      :text => "Great course!",
      :time => 1347589564,
      :rating => 4.0
  )

  (0..6).each do |day|
    place.periods.create(
        :day => day,
        :opening_time => 700,
        :closing_time => 1700
    )
  end

#-------------------------------------------

  # Create a place
  place = Place.create(
      :permanent_id_num => "84",
      :name => "Planet Granite",
      :address => "924 Mason Street, San Francisco, CA, United States",
      :phone_number => "(415) 692-3434",
      :rating => 5.0,
      :website => "http://www.planetgranite.com/",
      :price_level => 0,
      :review_summary => "Climbing, Yoga & Fitness",
      :duration => 2.0
  )

  # Create the associated models: Category, Reviews, Periods, and Photos
  place.category = Category.find_or_create_by_name("sports")

  place.reviews.create(
      :author => "Tori Lesikar",
      :text => "PG is the Four Seasons/ Ritz Carlton of climbing gyms. I&#39;ve tried to go to other gyms to keep up my skills when I&#39;ve been out of town, but nothing compares. Routes are changed every 6 weeks (sectioned off across the gym, so they&#39;re always evolving), holes are always clean, staff is knowledgeable and safety is a top priority. They also offer great yoga and fitness classes. Plus, it doesn&#39;t hurt that you get to experience Crissy Field every time you climb!",
      :time => 1370757376,
      :rating => 5.0
  )

  place.reviews.create(
      :author => "Andrea Nataly Ruiz",
      :text => "A wonderful place to be. I was a member for 2 years - missed it so much I&#39;m now back at it. Great for both top-ropers and boulderers. Complete with 2 yoga studios, plenty of cardio machines and strength equipment. On a typical climbing day you&#39;ll find yourself surrounded by friendly folk, good vibes and lovely natural lighting. The icing on the cake: It&#39;s located across from Crissy Field, which allows for spectacular views.",
      :time => 1359585626,
      :rating => 5.0
  )

  place.reviews.create(
      :author => "Emily Smith",
      :text => "This is by far the coolest gym I&#39;ve ever been to. They have yoga classes, amazing rock climbing facilities, and friendly staff. They&#39;ll have competitions every once in a while where you can drink beer and eat pizza and socialize. Such a great place to come and burn some serious calories.",
      :time => 1363917737,
      :rating => 5.0
  )

  place.periods.create(
      :day => 0,
      :opening_time => 800,
      :closing_time => 1800
  )
  place.periods.create(
      :day => 1,
      :opening_time => 600,
      :closing_time => 2300
  )
  place.periods.create(
      :day => 2,
      :opening_time => 600,
      :closing_time => 2300
  )
  place.periods.create(
      :day => 3,
      :opening_time => 600,
      :closing_time => 2300
  )
  place.periods.create(
      :day => 4,
      :opening_time => 600,
      :closing_time => 2300
  )
  place.periods.create(
      :day => 5,
      :opening_time => 600,
      :closing_time => 2300
  )
  place.periods.create(
      :day => 6,
      :opening_time => 800,
      :closing_time => 2000
  )

#-------------------------------------------

  # Create a place
  place = Place.create(
      :permanent_id_num => "85",
      :name => "House of Air",
      :address => "926 Old Mason St, San Francisco, CA, United States",
      :phone_number => "(415) 345-9675",
      :rating => 4.5,
      :website => "http://www.houseofair.com/",
      :price_level => 2,
      :review_summary => "Indoor trampoline park located in The Presidio of San Francisco. Our athletic and recreational facility is host to open trampoline jump time, training, trampoline dodgeball and fitness classes.",
      :duration => 2.0
  )

  # Create the associated models: Category, Reviews, Periods, and Photos
  place.category = Category.find_or_create_by_name("sports")

  place.reviews.create(
      :author => "Megan Stevenson",
      :text => "I went to House of Air on a work retreat and it was a blast. The main attraction was trampoline dodgeball which we played via a bracket that lasted 90 minutes. It was a great way to get exercise and encourage some friendly competition amongst co-workers. The highlight for me was the big &quot;field&quot; of trampolines in the back. Something about jumping put a huge grin the face of even the most serious adults. It was a great workout too. I&#39;d definitely play dodgeball again with a big group of friends, but with a small group it is really fun to just jump.",
      :time => 1361463955,
      :rating => 4.0
  )

  place.reviews.create(
      :author => "Ivan Ballard",
      :text => "Great place for fun! They have all sorts of fun activities. They also have class opportunities, which would be a lot of fun, just haven&#39;t signed up yet!",
      :time => 1368217141,
      :rating => 5.0
  )

  (0..6).each do |day|
    place.periods.create(
        :day => day,
        :opening_time => 1000,
        :closing_time => 2200
    )
  end

#-------------------------------------------

  # Create a place
  place = Place.create(
      :permanent_id_num => "86",
      :name => "Berkeley Ironworks Climbing & Fitness",
      :address => "800 Potter Street, Berkeley, CA, United States",
      :phone_number => "(510) 981-9900",
      :rating => 4.5,
      :website => "http://www.touchstoneclimbing.com/bi.html",
      :price_level => 0,
      :review_summary => "Berkeley Ironworks is one of the largest Touchstone gyms and has incredible climbing terrain along with a full set of weight & exercise equipment. We also have Yoga, Pilates, Indoor Cycling and more!",
      :duration => 2.0
  )

  # Create the associated models: Category, Reviews, Periods, and Photos
  place.category = Category.find_or_create_by_name("sports")

  place.reviews.create(
      :author => "Vera Devera",
      :text => "I&#39;ve been a member here for a couple years and by far, it&#39;s the one I&#39;m most loyal to. I haven&#39;t rock climbed here yet and workout instead. The equipment isn&#39;t the most state of the art, but it gets the job done. They offer a variety of classes, from TRX to kickboxing, yoga and spin. My only complaint is that a handful of members think it&#39;s okay to walk around barefoot and use equipment. VERY INAPPROPRIATE and unsanitary. The staff working the front desk are always friendly but I wish they would enforce basic gym rules like mandatory shoes in the weight room. The locker room here is much better than its sister gym, Great Western Power Company in Oakland -- roomier, dry sauna and plenty of showers and concrete floors. For the price, I think Ironworks is a fair deal -- I go to GWPC for Crossfit.",
      :time => 1371852020,
      :rating => 5.0
  )

  place.reviews.create(
      :author => "Brandon Nauman",
      :text => "As a longtime member, I&#39;ll be the first to say Ironworks has excellent potential. Unfortunately this place is FILTHY. It smells very bad everywhere. The equipment is very old and most of the cardio machines need replacing (not more epoxy). We pay a lot of money - it&#39;s nice this builds you new gyms in the far east bay, south bay, and Dogpatch...for them. How about reinvesting some of this money back into the place that butters your bread, huh? To other members: Deodorant and an occasional shower won&#39;t kill you or make you any less hippy-hipster whatever you are. I listen to the Dead too, I just don&#39;t smell like the dead. Also, you look better with your shirt on for the love of God. You can&#39;t see that pasty white back fat in the mirror I guess. To management: You members&#39; hygeinic shortcomings don&#39;t have to equate to an obvious lack of effort on your part to keep your gym clean. It is disgusting and it smells so bad in the men&#39;s locker room that it&#39;s almost intolerable. Prevent infections - please take action on this.",
      :time => 1368143981,
      :rating => 4.0
  )

  place.reviews.create(
      :author => "Brianna Foster",
      :text => "outstanding help, awesome time!",
      :time => 1362280581,
      :rating => 4.5
  )

  place.periods.create(
      :day => 0,
      :opening_time => 900,
      :closing_time => 2000
  )
  place.periods.create(
      :day => 1,
      :opening_time => 600,
      :closing_time => 2200
  )
  place.periods.create(
      :day => 2,
      :opening_time => 600,
      :closing_time => 2300
  )
  place.periods.create(
      :day => 3,
      :opening_time => 600,
      :closing_time => 2200
  )
  place.periods.create(
      :day => 4,
      :opening_time => 600,
      :closing_time => 2300
  )
  place.periods.create(
      :day => 5,
      :opening_time => 600,
      :closing_time => 2200
  )
  place.periods.create(
      :day => 6,
      :opening_time => 900,
      :closing_time => 2000
  )

#-------------------------------------------

  # Create a place
  place = Place.create(
      :permanent_id_num => "87",
      :name => "Fourth Street Bowl",
      :address => "1441 North 4th Street, San Jose, CA, United States",
      :phone_number => "(408) 453-5555",
      :rating => 4.0,
      :website => "http://www.4thstreetbowl.com/",
      :price_level => 2,
      :review_summary => "32 Lane Bowling Alley located just North of Downtown San Jose. Coffee Shop, Lounge, Karaoke, Billiards.",
      :duration => 2.0
  )

  # Create the associated models: Category, Reviews, Periods, and Photos
  place.category = Category.find_or_create_by_name("sports")

  place.reviews.create(
      :author => "Tiffanie Burrage",
      :text => "Went here for breakfast! Believe it, I ate a great breakfast here twice! The service was spot on and the food was wonderful. Very unexpected. Make a note that they do not serve bloody mary&#39;s until 11am. ;-)",
      :time => 1371594899,
      :rating => 4.0
  )

  place.reviews.create(
      :author => "Kwadwo Osei",
      :text => "this place is excellent",
      :time => 1365877313,
      :rating => 4.0
  )

  (0..6).each do |day|
    place.periods.create(
        :day => day,
        :opening_time => 900,
        :closing_time => 130
    )
  end

#-------------------------------------------

  # Create a place
  place = Place.create(
      :permanent_id_num => "88",
      :name => "San Jose Municipal Golf Course",
      :address => "1560 Oakland Road, San Jose, California, United States",
      :phone_number => "(408) 441-4653",
      :rating => 3.5,
      :website => "http://www.sjmuni.com/",
      :price_level => 0,
      :review_summary => "The South Bay's Best Golf Hangout",
      :duration => 3.0
  )

  # Create the associated models: Category, Reviews, Periods, and Photos
  place.category = Category.find_or_create_by_name("sports")

  place.reviews.create(
      :author => "Willard Dark",
      :text => "One of my favorite courses to play at. Great prices and a fun, yet challenging course.",
      :time => 1349306130,
      :rating => 4.0
  )

  place.reviews.create(
      :author => "Tom C",
      :text => "Great bang for your golf buck. All greens resurfaced in 2010-2011. Good practice facilities, improved food &amp; good staff.",
      :time => 1325874464,
      :rating => 3.0
  )

  place.reviews.create(
      :author => "Bart B",
      :text => "Brand new greens are awesome and the staff is great. Never disappointed with a meal from the restaurant either.",
      :time => 1314899181,
      :rating => 3.5
  )

  place.periods.create(
      :day => 0,
      :opening_time => 600,
      :closing_time => 2200
  )
  place.periods.create(
      :day => 1,
      :opening_time => 900,
      :closing_time => 2200
  )
  place.periods.create(
      :day => 2,
      :opening_time => 600,
      :closing_time => 2200
  )
  place.periods.create(
      :day => 3,
      :opening_time => 900,
      :closing_time => 2200
  )
  place.periods.create(
      :day => 4,
      :opening_time => 600,
      :closing_time => 2200
  )
  place.periods.create(
      :day => 5,
      :opening_time => 600,
      :closing_time => 2200
  )
  place.periods.create(
      :day => 6,
      :opening_time => 600,
      :closing_time => 2200
  )

#-------------------------------------------

  # Create a place
  place = Place.create(
      :permanent_id_num => "89",
      :name => "Lake Chabot Golf Course",
      :address => "11450 Golf Links Road, Oakland, CA, United States",
      :phone_number => "(510) 351-5812",
      :rating => 4.5,
      :website => "http://www.lakechabotgolf.com/",
      :price_level => 0,
      :review_summary => "Lake Chabot Golf Course is a banquet facility that provides discount golf and golf lessons in the East Bay. For more information you can call 510-567-4254.",
      :duration => 2.0
  )

  # Create the associated models: Category, Reviews, Periods, and Photos
  place.category = Category.find_or_create_by_name("sports")

  place.reviews.create(
      :author => "Willard Dark",
      :text => "One of my favorite courses to play at.",
      :time => 1349306140,
      :rating => 4.5
  )

  (0..6).each do |day|
    place.periods.create(
        :day => day,
        :opening_time => 900,
        :closing_time => 2000
    )
  end

  #-------------------------------------------

  # Create a place
  place = Place.create(
      :permanent_id_num => "90",
      :name => "LaLanne Fitness",
      :address => "960 Howard Street, San Francisco, CA, United States",
      :phone_number => "(415) 512-7645",
      :rating => 4.5,
      :website => "http://www.lalannefitness.com/",
      :price_level => 0,
      :review_summary => "Getting started with us is simple â give us a call at 415.512.7645 or email info@lalannefitness.com to schedule your Free Intro Class!",
      :duration => 2.0
  )

  # Create the associated models: Category, Reviews, Periods, and Photos
  place.category = Category.find_or_create_by_name("sports")

  place.reviews.create(
      :author => "Abhimanyu Ardagh",
      :text => "I wanted to try out CrossFit for many years and so glad I finally checked it out, should of done so forever ago! LaLanne Fitness excepted me instantly into the community and have enjoyed every little moment. CrossFit is really the best thing that anyone can do for themselves and there is no better place to frist try out then LaLanne Fitness. They have the greatest coaches who are very knowledgeable and friendly but most important of all they push you to become a whole new better you. If your debating about trying it out, stop! They even have a free into class so there is really nothing to loose!",
      :time => 1367542554,
      :rating => 4.0
  )

  place.reviews.create(
      :author => "Joel Corpus",
      :text => "If you&#39;re looking for a CrossFit gym, look no further! Lalanne Fitness is an amazing facility with tons of space and equipment. The coaches are fantastic and the community is strong and supportive. The gym is in a prime location, located near the Powell Muni and Bart station as well as multiple bus lines. When looking for a CrossFit gym, I always look for excellent coaches that I can relate to, a family type community, strong programming that focuses on strength, endurance and agility and competition. Lalanne Fitness offers all of this and more and I highly recommend stopping by for a workout to check it out. CrossFit has changed my life and it&#39;s been an amazing experience seeing myself grow into the athlete that I am today. I&#39;m happy to call Lalanne Fitness my home and hope to see you in the gym one day!",
      :time => 1367437597,
      :rating => 5.0
  )

  place.periods.create(
      :day => 0,
      :opening_time => 830,
      :closing_time => 1130
  )
  place.periods.create(
      :day => 1,
      :opening_time => 600,
      :closing_time => 1930
  )
  place.periods.create(
      :day => 2,
      :opening_time => 600,
      :closing_time => 1930
  )
  place.periods.create(
      :day => 3,
      :opening_time => 600,
      :closing_time => 1930
  )
  place.periods.create(
      :day => 4,
      :opening_time => 600,
      :closing_time => 1930
  )
  place.periods.create(
      :day => 5,
      :opening_time => 600,
      :closing_time => 1930
  )
  place.periods.create(
      :day => 6,
      :opening_time => 830,
      :closing_time => 1130
  )


#------------------------------------ ADVENTURE -------------------------------------------------#

  # Create a place
  place = Place.create(
      :permanent_id_num => "101",
      :name => "California's Great America",
      :address => "4701 Great America Parkway, Santa Clara, CA, United States",
      :phone_number => "(408) 988-1776",
      :rating => 4.0,
      :website => "http://www.cagreatamerica.com/",
      :price_level => 0,
      :review_summary => "Californiaâs Great America, Northern Californiaâs biggest and best choice for world-class family fun and thrills, celebrates 37 years of entertaining families. Park open March through October.",
      :duration => 3.0
  )

  # Create the associated models: Category, Reviews, Periods, and Photos
  place.category = Category.find_or_create_by_name("adventure")

  place.reviews.create(
      :author => "Julee Lee",
      :text => "I haven&#39;t been to an amusement park in years so when I got tickets for discounted prices, I jumped on it. I got a group of friends together for a fun-filled time. It was a little misty, but I didn&#39;t think it would affect the rides. Unfortunately I was wrong. A lot of the rides weren&#39;t open because of the rain, and the rides which were open we ended up spending hours (let me emphasize the &#39;s&#39;) waiting in line which we would be on for 1 minute. I don&#39;t think I&#39;ll be heading back anytime soon and if I do, I&#39;ll splurge and get the ticket which allows you to cut everyone and skip to the front of the line.",
      :time => 1372292658,
      :rating => 4.0
  )

  place.reviews.create(
      :author => "Vladislav Kravtsov",
      :text => "Fun park with a great location. It&#39;s also a very good value with the season pass. Highlight of the park is Flight Deck (though I still call it Top Gun), and Demon. Very fun. Drop Zone... err... Tower still provides a decent thrill (and a good view). Plus, new roller coaster for this year.",
      :time => 1368742717,
      :rating => 4.0
  )

  place.reviews.create(
      :author => "Ashlynn Blue",
      :text => "I absoultly love great america because of the rides.The lines go fast,and theres a lot of fun things to do there. They have kid rides,mild rides, and even thrill rides for the teens or adults. They even have height limits like if you arent 54&quot; inches than you cant go on Flight Deck.",
      :time => 1362152884,
      :rating => 4.0
  )

  (0..6).each do |day|
    place.periods.create(
        :day => day,
        :opening_time => 1000,
        :closing_time => 2000
    )
  end

#-------------------------------------------

  # Create a place
  place = Place.create(
      :permanent_id_num => "102",
      :name => "House of Air",
      :address => "926 Old Mason St, San Francisco, CA, United States",
      :phone_number => "(415) 345-9675",
      :rating => 4.5,
      :website => "http://www.houseofair.com/",
      :price_level => 2,
      :review_summary => "Indoor trampoline park located in The Presidio of San Francisco. Our athletic and recreational facility is host to open trampoline jump time, training, trampoline dodgeball and fitness classes.",
      :duration => 2.0
  )

  # Create the associated models: Category, Reviews, Periods, and Photos
  place.category = Category.find_or_create_by_name("adventure")

  place.reviews.create(
      :author => "Megan Stevenson",
      :text => "I went to House of Air on a work retreat and it was a blast. The main attraction was trampoline dodgeball which we played via a bracket that lasted 90 minutes. It was a great way to get exercise and encourage some friendly competition amongst co-workers. The highlight for me was the big &quot;field&quot; of trampolines in the back. Something about jumping put a huge grin the face of even the most serious adults. It was a great workout too. I&#39;d definitely play dodgeball again with a big group of friends, but with a small group it is really fun to just jump.",
      :time => 1361463955,
      :rating => 4.0
  )

  place.reviews.create(
      :author => "Ivan Ballard",
      :text => "Great place for fun! They have all sorts of fun activities. They also have class opportunities, which would be a lot of fun, just haven&#39;t signed up yet!",
      :time => 1368217141,
      :rating => 5.0
  )

  place.reviews.create(
      :author => "Derek Chan",
      :text => "An amazing time out with co-workers. Trampoline dodgeball is an insanely fun (and relatively safe) way to blow off steam, and you get to throw soft balls at people&#39;s heads. How is that not awesome? House of Air&#39;s facilities are clean and spacious, with multiple trampolines set up in a couple large areas - one for general bouncing and fun, and one dedicated to the dodgeball arena. I do recommend that people be in reasonable shape before coming here, with strong ankles and knees and decent aerobic capacity. Trampolines might look like they&#39;re for kids, but the possibility for injury is very real.",
      :time => 1361476990,
      :rating => 4.5
  )

  place.periods.create(
      :day => 0,
      :opening_time => 1000,
      :closing_time => 2100
  )
  place.periods.create(
      :day => 1,
      :opening_time => 1000,
      :closing_time => 2100
  )
  place.periods.create(
      :day => 2,
      :opening_time => 1000,
      :closing_time => 1900
  )
  place.periods.create(
      :day => 3,
      :opening_time => 1000,
      :closing_time => 2100
  )
  place.periods.create(
      :day => 4,
      :opening_time => 1000,
      :closing_time => 2100
  )
  place.periods.create(
      :day => 5,
      :opening_time => 1000,
      :closing_time => 2200
  )
  place.periods.create(
      :day => 6,
      :opening_time => 1000,
      :closing_time => 2200
  )

#-------------------------------------------

  # Create a place
  place = Place.create(
      :permanent_id_num => "103",
      :name => "Lemans Karting",
      :address => "45957 Hotchkiss Street, Fremont, CA, United States",
      :phone_number => "(510) 770-9001",
      :rating => 4.5,
      :website => "http://www.lemanskarting.com/",
      :price_level => 0,
      :review_summary => "Experience the speed and excitement of true wheel-to-wheel racing action at LeMans Karting, Silicon Valleyâs ONLY indoor-outdoor kart racing center.",
      :duration => 2.0
  )

  # Create the associated models: Category, Reviews, Periods, and Photos
  place.category = Category.find_or_create_by_name("adventure")

  place.reviews.create(
      :author => "eric scheible",
      :text => "The Tuesday night enduro is the best bang for the buck. It is for the more advanced racers and features pit stops and driver changes. I highly recommend it.",
      :time => 1362780428,
      :rating => 4.0
  )

  place.reviews.create(
      :author => "Sean Wang",
      :text => "I had a great experience here! After watching a short video, you get to put on your helmet and strap into the kart. For $25, you get 10 minutes, which is about 15 laps if you&#39;re a decent driver, and up to about 18 if you&#39;re a real speed demon. At the end, you can get a printout of your lap times and standing among the other racers.",
      :time => 1357413945,
      :rating => 5.0
  )

  place.reviews.create(
      :author => "Charlie Hodges",
      :text => "Great place to race karts. Their karts are fast, handle very well, the indoor-to-outdoor transition makes the racing more fun, and scheduling is easy or you can walk-in with very little wait. Also, you don&#39;t have wear a silly racing suit (optional)- just make sure you wear closed toe shoes, no sandals. I&#39;ve had no issues with the staff, very straight forward and enforce the rules as needed. Also, you can race the outdoor portion at night which adds some degree of challenge. I highly recommend this place over the &quot;other&quot; electric kart location in the South Bay.",
      :time => 1346798729,
      :rating => 4.5
  )

  place.periods.create(
      :day => 0,
      :opening_time => 900,
      :closing_time => 2100
  )
  place.periods.create(
      :day => 1,
      :opening_time => 1500,
      :closing_time => 2100
  )
  place.periods.create(
      :day => 2,
      :opening_time => 1200,
      :closing_time => 2100
  )
  place.periods.create(
      :day => 3,
      :opening_time => 1200,
      :closing_time => 2100
  )
  place.periods.create(
      :day => 4,
      :opening_time => 1200,
      :closing_time => 2100
  )
  place.periods.create(
      :day => 5,
      :opening_time => 1200,
      :closing_time => 2300
  )
  place.periods.create(
      :day => 6,
      :opening_time => 900,
      :closing_time => 2300
  )

#-------------------------------------------

  # Create a place
  place = Place.create(
      :permanent_id_num => "104",
      :name => "Gokart Racer",
      :address => "1541 Adrian Road, Burlingame, CA, United States",
      :phone_number => "(650) 692-7223",
      :rating => 4.0,
      :website => "http://gokartracer.com/",
      :price_level => 0,
      :review_summary => "Great for large and small company parties, team building, birthday parties, bachelor parties or any kind of group events.",
      :duration => 2.0
  )

  # Create the associated models: Category, Reviews, Periods, and Photos
  place.category = Category.find_or_create_by_name("adventure")

  place.reviews.create(
      :author => "Fran V",
      :text => "I recently went here with a few friends to celebrate a birthday. After you register and pay, you go to the locker room and you get to put on a racing suit. Then report to the designed room where they play a safety video for the do&#39;s and don&#39;ts on the track. They make every precaution to make sure you follow the rules and stay safe on the track. After the 10 minute video, you grab a helmet and get on the track. The group that I drove with got to race on the SuperTrack, which lasts about 10-15 minutes. If you have a need for speed, this might be the place for you!",
      :time => 1341424862,
      :rating => 4.0
  )

  place.reviews.create(
      :author => "Charlie Hodges",
      :text => "I&#39;ve been here several times and the experiences have been great. Scheduling, staff, and facility are top-notch. I highly recommend GKR.",
      :time => 1344277142,
      :rating => 4.0
  )

  place.periods.create(
      :day => 0,
      :opening_time => 1000,
      :closing_time => 2100
  )
  place.periods.create(
      :day => 1,
      :opening_time => 1200,
      :closing_time => 2200
  )
  place.periods.create(
      :day => 2,
      :opening_time => 1200,
      :closing_time => 2200
  )
  place.periods.create(
      :day => 3,
      :opening_time => 1200,
      :closing_time => 2200
  )
  place.periods.create(
      :day => 4,
      :opening_time => 1200,
      :closing_time => 2200
  )
  place.periods.create(
      :day => 5,
      :opening_time => 1100,
      :closing_time => 0
  )
  place.periods.create(
      :day => 6,
      :opening_time => 1000,
      :closing_time => 0
  )

#-------------------------------------------

  # Create a place
  place = Place.create(
      :permanent_id_num => "105",
      :name => "Laser Quest",
      :address => "1400 North Shoreline Boulevard, Mountain View, CA, United States",
      :phone_number => "(650) 965-9800",
      :rating => 4.0,
      :website => "http://www.laserquest.com/mountainview",
      :price_level => 0,
      :review_summary => "Laser Quest is an all ages entertainment venue combining the classic games of hide-and-seek and tag with a high tech twist. Great for Team Building, Groups and Birthdays.Up to 35 players in each game.",
      :duration => 2.0
  )

  # Create the associated models: Category, Reviews, Periods, and Photos
  place.category = Category.find_or_create_by_name("adventure")

  place.reviews.create(
      :author => "Dee M",
      :text => "Played against gamers and came in 7th, not bad. Hee hee",
      :time => 1371858898,
      :rating => 4.0
  )

  place.reviews.create(
      :author => "Katie brown",
      :text => "I went there for my Birthday once and it was amazing.",
      :time => 1364835153,
      :rating => 4.0
  )

  place.reviews.create(
      :author => "Molly Bierman",
      :text => "Came here last week for a work team-building offsite -- had just as much fun as the last time I went laser tagging which I think was back in the previous millennium. I can&#39;t speak to the prices (thanks to my employer for footing the bill!) or how it&#39;d be during a weekend ie with lots of kids around, but overall everyone in our group seemed to have a good time. The actual course is quite large and intricate, with numerous levels / ramps so you can shoot high and low. They offer a number of different battle choices, such as teams, every man for himself, capture the flag (where you shoot at a base), etc etc. Word to the wise: your team earns more points for a hit than you lose for getting hit, so it pays to be aggressive! After each game they give you a scorecard that details all your hits, the outcome, how you compared to others, etc. Games last about 20 minutes. The gun was heavier than I expected -- sad to say a lot of us were sweating after each round (we played 3 rounds for 20 minutes apiece). The staff was generally fine -- about as professional as you&#39;d expect for people whose day job is at a laser tag place (which is all I needed, honestly). They have some arcade games and a party room if you were to do a birthday here or something and have cake. Good access to the highway and ample parking as well. Do not wear light colors as the entire laser tag area is blacklit so you will stick out like a sore thumb.",
      :time => 1331271653,
      :rating => 4.0
  )

  place.periods.create(
      :day => 0,
      :opening_time => 1000,
      :closing_time => 2000
  )
  place.periods.create(
      :day => 2,
      :opening_time => 1600,
      :closing_time => 2100
  )
  place.periods.create(
      :day => 3,
      :opening_time => 1600,
      :closing_time => 2100
  )
  place.periods.create(
      :day => 4,
      :opening_time => 1600,
      :closing_time => 2100
  )
  place.periods.create(
      :day => 5,
      :opening_time => 1500,
      :closing_time => 0
  )
  place.periods.create(
      :day => 6,
      :opening_time => 1000,
      :closing_time => 0
  )

#-------------------------------------------

  # Create a place
  place = Place.create(
      :permanent_id_num => "106",
      :name => "Dart Ops",
      :address => "1150 El Camino Real #141, San Bruno, CA, United States",
      :phone_number => "(650) 952-2297",
      :rating => 5.0,
      :website => "http://www.dartops.com/",
      :price_level => 0,
      :review_summary => "The first-of-its-kind shooting arena for air-blasted foam darts. We have 7,200 square foot of party place for team shootouts and team building exercise. A great place for parties and friendly fun!",
      :duration => 2.0
  )

  # Create the associated models: Category, Reviews, Periods, and Photos
  place.category = Category.find_or_create_by_name("adventure")

  place.reviews.create(
      :author => "kelly C",
      :text => "I love this place!",
      :time => 1331271653,
      :rating => 4.0
  )
  place.periods.create(
      :day => 0,
      :opening_time => 1100,
      :closing_time => 1900
  )
  place.periods.create(
      :day => 1,
      :opening_time => 1000,
      :closing_time => 2100
  )
  place.periods.create(
      :day => 2,
      :opening_time => 1000,
      :closing_time => 2100
  )
  place.periods.create(
      :day => 3,
      :opening_time => 1000,
      :closing_time => 2130
  )
  place.periods.create(
      :day => 4,
      :opening_time => 1000,
      :closing_time => 2100
  )
  place.periods.create(
      :day => 5,
      :opening_time => 1000,
      :closing_time => 2100
  )
  place.periods.create(
      :day => 6,
      :opening_time => 1000,
      :closing_time => 2100
  )

#-------------------------------------------

  # Create a place
  place = Place.create(
      :permanent_id_num => "107",
      :name => "KGB Kiteboarding",
      :address => "3310 Powell Street, Emeryville, CA, United States",
      :phone_number => "(510) 967-8014",
      :rating => 4.5,
      :website => "http://www.kgbswag.com/",
      :price_level => 0,
      :review_summary => "IKO Affiliated kiteboarding Center and Shop. Your Bay area kiteboarding headquarters. Offering lessons and gear for new and experienced kiters. Best, Airush, Dakine and more.",
      :duration => 2.0
  )

  # Create the associated models: Category, Reviews, Periods, and Photos
  place.category = Category.find_or_create_by_name("adventure")

  place.reviews.create(
      :author => "Alan LaMielle",
      :text => "Received a 2 hour lesson as a gift. Super happy with the experience. Had a great time. First learned about the basics of wind, launching your kite on land, and kite safety. Then we headed to the water and started to figure out how make runs up and down the shore. Didn&#39;t quite get to using a board, but next lesson is where that would happen. Very glad for the gift!",
      :time => 1350274212,
      :rating => 4.5
  )

  (0..6).each do |day|
    place.periods.create(
        :day => day,
        :opening_time => 1000,
        :closing_time => 1900
    )
  end

#-------------------------------------------
  # Create a place
  place = Place.create(
      :permanent_id_num => "108",
      :name => "California Hang Gliding",
      :address => "San Rafael, CA 94901",
      :phone_number => "(650) 451-2549",
      :rating => 4.0,
      :website => "http://www.californiahg.com",
      :price_level => 1,
      :review_summary => "Tandem hang gliding flights and solo flying lessons.",
      :duration => 2.0
  )

  # Create the associated models: Category, Reviews, Periods, and Photos
  place.category = Category.find_or_create_by_name("adventure")

  place.reviews.create(
      :author => "Mason W.",
      :text => "Perfect experience--this was my first time hang gliding, and it prompted me to write my first yelp review. Paris was awesome, the views were awesome, and the flight was unbelievable. My girlfriend bought me the gift certificate that got me the flight. Since I'm not a big risk-taker, I always get a little nervous before I do things like sky diving/hang gliding, and the experience is immeasurably better when I arrive and the person with my life in their hands is cool and comfortable and having a good time too. That's how it was. There are two locations. We flew at the Mt. Tamalpais location, and it was beautiful. Steep mountains, tall pine trees, and a nice sandy beach to land on. My flight was a mix of peaceful gliding and adrenalin producing dive bombs where my feet nicked the tree tops. It was perfect.",
      :time => 1350274212,
      :rating => 4.0
  )

  (0..6).each do |day|
    place.periods.create(
        :day => day,
        :opening_time => 800,
        :closing_time => 2000
    )
  end

#-------------------------------------------

  # Create a place
  place = Place.create(
      :permanent_id_num => "109",
      :name => "Bay Area Skydiving",
      :address => "6901 Armstrong Rd Byron, CA 94514",
      :phone_number => "(925) 634-7575",
      :rating => 5.0,
      :website => "http://www.bayareaskydiving.com",
      :price_level => 2,
      :review_summary => "Bay Area Skydiving is family owned and operated. We have been in business for over 20 years, have maintained an impeccable safety record. The owner, Clay Bonavito, has been involved with skydiving in Northern California for more than 25 years. Clay also heads up our video department, and with over 9,000 camera jumps is certainly one of the most experienced camera flyers in this area. Many of our instructional staff have over 10,000 jumps and we have many world record holders and experienced instructors to help you skydive.",
      :duration => 2.0
  )

  # Create the associated models: Category, Reviews, Periods, and Photos
  place.category = Category.find_or_create_by_name("adventure")

  place.reviews.create(
      :author => "Tiffany H.",
      :text => "The instructors were incredible and the whole place has a really fun air to it. This was my first skydiving experience. I'm still alive, so they deserve every one of those 5 stars.",
      :time => 1371858898,
      :rating => 5.0
  )

  (4..6).each do |day|
    place.periods.create(
        :day => day,
        :opening_time => 900,
        :closing_time => 2000
    )
  end

#-------------------------------------------

  # Create a place
  place = Place.create(
      :permanent_id_num => "110",
      :name => "iFLY SF Bay",
      :address => "31310 Alvarado Niles Rd, Union City, CA 94587",
      :phone_number => "(510) 489-4359",
      :rating => 4.0,
      :website => "http://sfbay.iflyworld.com/",
      :price_level => 1.0,
      :review_summary => "Fun for all ages! We fly people from 3 to 103 years old. No experience necessary and we provide all training. iFLY SF Bay is an incredibly safe and realistic experience.",
      :duration => 2.0
  )

  # Create the associated models: Category, Reviews, Periods, and Photos
  place.category = Category.find_or_create_by_name("adventure")

  place.reviews.create(
      :author => "Rita W.",
      :text => "I loved it so much. I had so much fun. It really worth trying. The trainer was so perfect. If you live in fremont or nearby I highly suggest coming here at least once.",
      :time => 1341424862,
      :rating => 4.0
  )

  (0..6).each do |day|
    place.periods.create(
        :day => day,
        :opening_time => 1000,
        :closing_time => 2300
    )
  end

#-------------------------------------------

else

  raise "Unknown SEEDS ENVIRONMENT > #{ENV['SEEDS_ENV']} specified! Use \"development\" OR \"production\""

end
