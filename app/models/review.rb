class Review < ActiveRecord::Base
  attr_accessible :author, :author_url, :rating, :text, :time, :place_id
  belongs_to :place

end
