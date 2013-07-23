#!/usr/bin/env ruby
# encoding: utf-8

require File.expand_path("../../../config/environment", __FILE__)
require_relative 'prediction.rb'

def prepare_text(text)
  return text.gsub(/[^A-Za-z0-9\-\s'’_]/, '').gsub(/\-/, ' ').downcase
end

configure
puts "API client configured"


training_status = check_status

if training_status["status"] == "error"
  if training_status["response"]["error"]["message"] == "No Model found. Model must first be trained."

    train
    puts "Model training started"

    training_status = check_status
    until  training_status["response"]["trainingStatus"] == "DONE" do
      sleep(20)
      training_status = check_status["response"]["trainingStatus"]
      puts "Model training " << training_status
    end
  else
    puts "Unknown error: #{training_status}"
  end
end

if training_status["response"]["trainingStatus"] == "DONE"
  # PREDICT the categories of the places that have text

  # Fetch places having review_summary and having no category
  summarized = Place.where("review_summary IS NOT NULL")
  categorized = Place.where("category_id IS NOT NULL")

  summarized_uncategorized = summarized - categorized

  # Request a prediction for each place
  summarized_uncategorized.each_with_index do |place, index|

    # Fetch the place types
    types =place.types
    types_names = types.shift.name # Inserts the name of the first type to the string of all types' names

    types.each do |type|
      types_names << " " << type.name
    end

    # Sanitize the review summary
    clean_summary = prepare_text(place.review_summary)

    # Send the prediction request
    input = [clean_summary,types_names]
    json_result = predict(input)

    if json_result["status"] == "success"
      category = Category.find_or_create_by_name(:name => json_result["response"]["outputLabel"])
      place.update_attribute(:category_id, category.id)
      puts "Predicted category\"#{json_result["response"]["outputLabel"]}\" for place #{index}"
    else
      puts "Oops! Prediction failed for place #{index}, Message: #{json_result["message"]}"
    end

  end
end
