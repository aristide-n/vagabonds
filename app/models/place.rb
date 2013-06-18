class Place < ActiveRecord::Base
  attr_accessible :address, :address_lat, :address_lng, :name, :permanent_id_num, :phone_number, :price_level, :rating, :reference, :url, :website, :review_summary
  has_many :periods
  has_many :reviews
  has_many :events
  has_and_belongs_to_many :categories

end
