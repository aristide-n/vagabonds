class Place < ActiveRecord::Base
  attr_accessible :address, :address_lat, :address_lng, :name, :permanent_id_num, :phone_number, :price_level, :rating, :reference, :url, :website, :review_summary, :duration
  validates_uniqueness_of :permanent_id_num
  has_many :periods
  has_many :reviews
  has_many :events
  has_many :photos
  belongs_to :category
  has_and_belongs_to_many :types

  def add_type(type)
    self.types.find_by_name(type) ||
        (self.types << Type.find_or_create_by_name(:name => type)).last
  end

  def self.recommendations(params)
      @time_ratio = {food: 0.143, nightlife: 0, nature: 0, adventure: 0, sports: 0, city: 0}
      preferred_categories = params["categories"] << "Food"

      #setting time ratio based on selected categories by user
      total_categories = preferred_categories.length - 1
      base_ratio = 0.857   #24/28

      if preferred_categories.include? "Nightlife"
         @time_ratio[:nightlife] = 0.143 #4/28
         base_ratio = 0.714   #20/28
         total_categories= total_categories - 1
      end
      if preferred_categories.include? "Nature"
        @time_ratio[:nature] = base_ratio / total_categories
      end
      if preferred_categories.include? "Adventure"
        @time_ratio[:adventure] = base_ratio / total_categories
      end
      if preferred_categories.include? "Sports"
        @time_ratio[:sports] = base_ratio / total_categories
      end
      if preferred_categories.include? "City"
        @time_ratio[:city] = base_ratio / total_categories
      end

      preferred_categories.map!{|c| c.downcase}
      #pp preferred_categories
      # Query db for matching categories and budget
      places_inCategories = Place.joins(:category).where(categories: {name: preferred_categories})
      places_inBudget = places_inCategories.where("price_level <= ?", params["budget"]).order("rating DESC")

      #Select recommended places based on time ratio
      total_hours = 60
      food_time = 60 * @time_ratio[:food]
      nightlife_time = 60 * @time_ratio[:nightlife]
      nature_time = 60 * @time_ratio[:nature]
      city_time = 60 * @time_ratio[:city]
      adventure_time = 60 * @time_ratio[:adventure]
      sports_time = 60 * @time_ratio[:sports]
      recommended_places = []
      places_inBudget.each do |place|
           if place.category.name == "food" && food_time > 0
             recommended_places << place
                 food_time -= place.duration
                 total_hours -= place.duration
           end

          if place.category.name == "nightlife" && nightlife_time > 0
             recommended_places << place
             nightlife_time -= place.duration
             total_hours -= place.duration
          end

           if place.category.name == "nature" && nature_time > 0
             recommended_places << place
             nature_time -= place.duration
             total_hours -= place.duration
           end

           if place.category.name == "adventure" && adventure_time > 0
             recommended_places << place
             adventure_time -= place.duration
             total_hours -= place.duration
           end

           if place.category.name == "sports" && sports_time > 0
             recommended_places << place
             sports_time -= place.duration
             total_hours -= place.duration
           end

           if place.category.name == "city" && city_time > 0
             recommended_places << place
             city_time -= place.duration
             total_hours -= place.duration
           end

      end

=begin
      d = 0
      recommended_places.each do |place|
        pp place.name
        d += place.duration
      end
      pp d.round(2).to_s("F")
=end

# Correspond chosen dates with period table day number
      week_days = {}
      week_days[0] = Date.strptime(params["start_date"], "%m/%d/%Y").wday
      week_days[1] = Date.strptime(params["end_date"], "%m/%d/%Y").wday
      final_activity_list = scheduler(recommended_places, week_days)
     # pp final_activity_list
      return recommended_places
  end

  def self.scheduler(top_places, week_days)

    @num_of_days = 2
    night_life_hrs_a_day = 0
    @food_hrs_a_day = 2
    @day_start_time = 8
    @lunch_start_time = 13
    @dinner_start_time = 19
    @night_life_start_time = 20

    rem_hrs_in_each_day = {}
    category_max_hours = {}

    if(@time_ratio["nightlife"] == 0)
      max_hrs_for_trip = 24

    else
      max_hrs_for_trip = 28
      night_life_hrs_a_day = 2

    end

    scheduled_places = Array.new(@num_of_days) { Array.new(max_hrs_for_trip/2) { } }
    pp max_hrs_for_trip/2
    @time_ratio.each { |category, hours| category_max_hours[category.to_s] = hours * max_hrs_for_trip }

    days = @num_of_days - 1

    while days >= 0 do
      rem_hrs_in_each_day[days] = (max_hrs_for_trip / @num_of_days) - @food_hrs_a_day - night_life_hrs_a_day

      days = days - 1
    end

    current_food_day = 1
    current_nightlife_day = 1

    top_places.each do |place|
      #pp place.name

      if place.duration <= category_max_hours[place.category.name]
        if place.category.name == "food"

          if scheduled_places[current_food_day][@lunch_start_time - @day_start_time].nil?
            scheduled_places[current_food_day][@lunch_start_time - @day_start_time] = place
          else
            scheduled_places[current_food_day][@dinner_start_time - @day_start_time] = place
            current_food_day -= 1
          end
          category_max_hours[place.category.name] -= place.duration

        elsif place.category.name == "nightlife"

          if scheduled_places[current_nightlife_day][@night_life_start_time - @day_start_time].nil?
            scheduled_places[current_nightlife_day].fill(place, (@night_life_start_time - @day_start_time)..((max_hrs_for_trip/2) - 1))
            current_nightlife_day -= 1
          end

          category_max_hours[place.category.name] -= place.duration

        else
          start_day = 0
          success = false

          day = 0
          while day != -1 && start_day < @num_of_days && success == false do

            day = get_available_day(place, rem_hrs_in_each_day, start_day)

            if day != -1

              result = find_slots(place, scheduled_places[day], week_days[day])

              success = result["success"]
              if success == true

                if result["splice_lunch_time"] == false
                  scheduled_places[day].fill(place, result["slot_start_idx"]..result["slot_end_idx"])
                else

                  scheduled_places[day].fill(place, result["slot_start_idx"]..(@lunch_start_time - @day_start_time - 1))
                  scheduled_places[day].fill(place, (@lunch_start_time - @day_start_time + 1)..result["slot_end_idx"])
                end

                rem_hrs_in_each_day[day] -= place.duration
                #category_max_hours[place.category.name] -= place.duration
              end
            end

            start_day = day + 1
          end
        end
      end
    end

    scheduled_places_list = collapse_repeated_slots(scheduled_places)
    scheduled_places_list
  end

  def self.get_available_day(place, rem_hrs_in_days, day)

    until place.duration <= rem_hrs_in_days[day] do
      day += 1
      if day == @num_of_days
        day = -1
        break
      end
    end

    day
  end

  def self.find_slots(place, scheduled_places_in_day, week_day)
    success = false
    place_opening_time = -1
    place_closing_time = -1
    splice_lunch_time = false
    result = {}

    if !Period.where(:place_id => place.id).empty?
      place_opening_period = Period.where(:place_id => place.id, :day => week_day)

      if !place_opening_period.empty?
        place_opening_time = place_opening_period.first.opening_time / 100
        place_closing_time = place_opening_period.first.closing_time / 100
      end
    else
      place_opening_time = @day_start_time
      place_closing_time = @dinner_start_time
    end

    if place_opening_time > -1
      opening_time = (place_opening_time - @day_start_time) >= 0 ? place_opening_time - @day_start_time : 0
      closing_time = place_closing_time <= @dinner_start_time ? (place_closing_time - @day_start_time) : @dinner_start_time - @day_start_time


      while opening_time <= closing_time - place.duration && success == false do
        slot_start_idx = opening_time
        i = opening_time
        num_of_slots = place.duration

        #pp scheduled_places_in_day # this is throwing nil after few runs when it reaches day 2, because the 2D array for 'scheduled_places' has index 0 and 1, you are passing 1 and 2 as 'day'
        if(i != (@lunch_start_time - @day_start_time))
        while i < (slot_start_idx + num_of_slots) &&
            (scheduled_places_in_day[i].nil? || (i == (@lunch_start_time - @day_start_time))) do

          if (i == (@lunch_start_time - @day_start_time))
            num_of_slots += 1
            splice_lunch_time = true
          end

          i += 1
        end

        if i == (slot_start_idx + num_of_slots)
          slot_end_idx = i - 1
          success = true
          result["slot_start_idx"] = slot_start_idx
          result["slot_end_idx"] = slot_end_idx
          result["splice_lunch_time"] = splice_lunch_time
        end
        end
        opening_time = i + 1
      end

    end

    result["success"] = success

    result

  end

  def self.collapse_repeated_slots(scheduled_places)

    pp scheduled_places[1]
    #pp scheduled_places[0].length
    day = 0
    scheduled_places_list = {}

    while day < scheduled_places.size() do

      places_list = []
      place_idx = 0
      last_non_repeated_place_idx = 0
      until !scheduled_places[day][place_idx].nil?
        place_idx += 1
      end
      places_list[last_non_repeated_place_idx] = scheduled_places[day][place_idx]
      place_idx += 1

      count = 1

      while place_idx < scheduled_places[day].size() do
        if !scheduled_places[day][place_idx].nil?
          if scheduled_places[day][place_idx] != places_list[last_non_repeated_place_idx]
            places_list[last_non_repeated_place_idx].duration = count
            count = 1
            last_non_repeated_place_idx += 1
            places_list[last_non_repeated_place_idx] = scheduled_places[day][place_idx]

          else
            count += 1
          end
        end
        place_idx += 1
      end

      scheduled_places_list[day] = places_list

      day += 1
    end
    scheduled_places_list
  end
=begin
  def self.scheduler(top_activities, week_days)

    @num_of_days = 2
    night_life_hrs_a_day = 0
    @food_hrs_a_day = 2
    @day_start_time = 8
    @lunch_start_time = 13
    @dinner_start_time = 19
    @night_life_start_time = 20

    rem_hrs_in_each_day = [0,0]
    category_max_hours = {}
    scheduled_activities = [@num_of_days + 1][1..10]

    if(@time_ratio["nightlife"] == 0)
      max_hrs_for_trip = 24

    else
      max_hrs_for_trip = 28
      night_life_hrs_a_day = 2
    end

    @time_ratio.each { |category, hours| category_max_hours[category.to_s] = hours * max_hrs_for_trip }

    rem_hrs_in_each_day.fill((max_hrs_for_trip / @num_of_days) - @food_hrs_a_day - night_life_hrs_a_day)
    pp   rem_hrs_in_each_day

    days = @num_of_days
    until days > 0 do
      scheduled_activities[days].fill(0)
      days -= 1
    end

    top_activities.each do |activity|

      if activity.duration <= category_max_hours[activity.category.name]
        if activity.category.name == "food"

          if scheduled_activities[@food_hrs_a_day][@lunch_start_time - @day_start_time] == 0  # find a way to figure if an element exists at a given index
            scheduled_activities[@food_hrs_a_day].insert([@lunch_start_time - @day_start_time], activity)
          else
            scheduled_activities[@food_hrs_a_day].insert([@dinner_start_time - @day_start_time], activity)
            food_time_day -= 1
          end

        elsif activity.category.name == "nightlife"

          if scheduled_activities[night_life_hrs_a_day][@night_life_start_time - @day_start_time] == 0
            scheduled_activities[night_life_hrs_a_day].insert([@night_life_start_time - @day_start_time], activity)
            night_life_hrs_a_day -= 1
          end

        else
          start_day = 1
          success = false
          day = 0

          while start_day <= @num_of_days && success == false do
            day = get_available_day(activity, rem_hrs_in_each_day, start_day)
            if day != 0
              success = find_slots(activity, scheduled_activities[day])
              if success == true
                if splice_lunch_time == false
                  scheduled_activities[day].fill(activity, slot_start_index..slot_end_index)
                else
                  scheduled_activities[day].fill(activity, slot_start_index..@lunch_start_time - 1)
                  scheduled_activities[day].fill(activity, @lunch_start_time + 1..slot_end_index)
                end
              end
            end

            start_day = day + 1
          end
        end
      end
    end

    scheduled_activity_list = collapse_repeated_slots(scheduled_activities)
    scheduled_activity_list
  end

  def self.get_available_day(activity, rem_hrs_in_days, day)

    until activity.duration <= rem_hrs_in_days[day] do
      day += 1
      if day > @num_of_days
        day = 0
        break
      end
    end

    day
  end

  def self.find_slots(activity, scheduled_activities_day)
    success = false
    ### activity_opening = Period.where("place_id = ? AND day = ?", activity.id, 2)
    start = activity.opening_time - @day_start_time
    closing_time = activity.closing_time < @dinner_start_time ? activity.closing_time : @dinner_start_time

    while start <= closing_time - duration && success == false do
      slot_start_idx = start
      i = start
      num_of_slots = slot_start_idx + activity.duration

      while i < num_of_slots &&
          (scheduled_activities_day[i] == 0 || scheduled_activities_day[i].category.name == "lunch") do
        i += 1
        if scheduled_activities_day[i].category.name == "lunch"
          num_of_slots += 1
          splice_lunch_time = true
        end
      end

      if i == num_of_slots
        slot_end_idx = i
        success = true
      end

      start += 1
    end

    success

  end

  def self.collapse_repeated_slots(scheduled_activities)

    day = 1
    scheduled_activity_list = [][]

    while day <= scheduled_activities.size() do

      last_non_repeated_activity_idx = 0
      scheduled_activity_list[day][last_non_repeated_activity_idx] = scheduled_activities[day][0]
      activity_idx = 1
      count = 1

      while activity_idx < scheduled_activities[day].size() do
        if scheduled_activities[day][activity_idx] != scheduled_activity_list[day][last_non_repeated_activity_idx]
          scheduled_activity_list[day][last_non_repeated_activity_idx].duration = count
          count = 1
          last_non_repeated_activity_idx += 1
          scheduled_activity_list[day][last_non_repeated_activity_idx] = scheduled_activities[day][activity_idx]

        else
          count += 1
        end

        activity_idx += 1
      end

      day += 1
    end
  end
=end
end
