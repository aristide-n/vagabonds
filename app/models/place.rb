class Place < ActiveRecord::Base
  attr_accessible :address, :address_lat, :address_lng, :name, :permanent_id_num, :phone_number, :price_level, :rating, :reference, :url, :website, :review_summary
  validates_uniqueness_of :permanent_id_num
  has_many :periods
  has_many :reviews
  has_many :events
  has_and_belongs_to_many :categories
  has_and_belongs_to_many :types

  def add_category(category)
    self.categories.find_by_name(category) ||
        (self.categories << Category.find_or_create_by_name(:name => category)).last
  end

  def add_type(type)
    self.types.find_by_name(type) ||
        (self.types << Type.find_or_create_by_name(:name => type)).last
  end

end
