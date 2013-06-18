class Event < ActiveRecord::Base
  attr_accessible :id_num, :start_time, :summary, :url, :place_id
  belongs_to :place

end
