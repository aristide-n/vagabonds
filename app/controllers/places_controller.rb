class PlacesController < ApplicationController

  def index
      @recommended_places
  end

  def itinerary
    @recommended_places = recommend
    @user_input = params
  end

  def recommend
     Place.recommendations(params)
  end

  def show
    @place = Place.find(params[:id])
  end
end