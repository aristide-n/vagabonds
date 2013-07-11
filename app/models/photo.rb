class Photo < ActiveRecord::Base
  attr_accessible :height, :reference_id, :width
  belongs_to :place

end
