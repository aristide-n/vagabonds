class Period < ActiveRecord::Base
  attr_accessible :closing_time, :day, :opening_time, :place_id
  belongs_to :place

end
