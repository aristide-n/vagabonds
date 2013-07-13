class Photo < ActiveRecord::Base
  attr_accessible :height, :reference_id, :width
  belongs_to :place

  PLACES_API_PHOTO_REQ_URL = "https://maps.googleapis.com/maps/api/place/photo?"
  def url
    return "#{PLACES_API_PHOTO_REQ_URL}maxwidth=#{width}&photoreference=#{reference_id}&sensor=false&key=#{ENV['PLACES_API_KEY']}"
  end

end
