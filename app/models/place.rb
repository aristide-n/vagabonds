class Place < ActiveRecord::Base
  attr_accessible :address, :address_lat, :address_lng, :name, :permanent_id_num, :phone_number, :price_level, :rating, :reference, :url, :website, :review_summary, :duration
  validates_uniqueness_of :permanent_id_num
  has_many :periods
  has_many :reviews
  has_many :events
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
           if place.category.name == "Food" && food_time > 0
             recommended_places << place
                 food_time -= place.duration
                 total_hours -= place.duration
           end

          if place.category.name == "Nightlife" && nightlife_time > 0
             recommended_places << place
             nightlife_time -= place.duration
             total_hours -= place.duration
          end

           if place.category.name == "Nature" && nature_time > 0
             recommended_places << place
             nature_time -= place.duration
             total_hours -= place.duration
           end

           if place.category.name == "Adventure" && adventure_time > 0
             recommended_places << place
             adventure_time -= place.duration
             total_hours -= place.duration
           end

           if place.category.name == "Sports" && sports_time > 0
             recommended_places << place
             sports_time -= place.duration
             total_hours -= place.duration
           end

           if place.category.name == "City" && city_time > 0
             recommended_places << place
             city_time -= place.duration
             total_hours -= place.duration
           end

      end

    return recommended_places
  end
end
