#!/usr/bin/env ruby

require File.expand_path("../../../config/environment", __FILE__)
require_relative 'prediction.rb'

configure
puts "API client configured"

train
puts "Model training started"

training_status = check_status["response"]["trainingStatus"]
until  training_status == "DONE" do
  sleep(20)
  training_status = check_status["response"]["trainingStatus"]
  puts "Model training " << training_status
end

# PREDICT the categories of the places that have text

# Fetch places having review_summary and having no category
#places = Place.arel_table
summarized = Place.where("review_summary IS NOT NULL")
categorized = Place.includes(:categories).where("categories.name IS NOT NULL")

summarized_uncategorized = summarized - categorized

# Request a prediction for each place
summarized_uncategorized.each_with_index do |place, index|

  # Fetch the place types
  types =place.types
  types_names = types.shift.name # Inserts the name of the first type to the string of all types' names

  types.each do |type|
    types_names << " " << type.name
  end

  # Send the prediction request
  input = [place.review_summary,types_names]
  json_result = predict(input)

  if json_result["status"] == "success"
    place.add_category(json_result["response"]["outputLabel"])
    puts "Predicted category\"#{json_result["response"]["outputLabel"]}\" for place #{index}"
  else
    puts "Oops! Prediction failed for place #{index}, Message: #{json_result["message"]}"
  end

end


def prepare_text(text)
  text.gsub(/[^0-9a-z \']/i, '')
end
