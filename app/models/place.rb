class Place < ActiveRecord::Base
  attr_accessible :address, :address_lat, :address_lng, :name, :permanent_id, :phone_number, :rating, :reference, :url, :website
end
