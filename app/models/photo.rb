class Photo < ActiveRecord::Base
  attr_accessible :height, :reference_id, :width, :uploaded
  belongs_to :place

  # This method associates the attribute ":uploaded" with a file attachment
  has_attached_file :uploaded

  PLACES_API_PHOTO_REQ_URL = "https://maps.googleapis.com/maps/api/place/photo?"
  def url
    return "#{PLACES_API_PHOTO_REQ_URL}maxwidth=#{width}&photoreference=#{reference_id}&sensor=false&key=#{ENV['PLACES_API_KEY']}"
  end

end
