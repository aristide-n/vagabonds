# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20130711041907) do

  create_table "categories", :force => true do |t|
    t.string   "name"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "categories_places", :id => false, :force => true do |t|
    t.integer "category_id"
    t.integer "place_id"
  end

  create_table "events", :force => true do |t|
    t.integer  "id_num"
    t.text     "summary"
    t.string   "url"
    t.integer  "start_time"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
    t.integer  "place_id"
  end

  create_table "periods", :force => true do |t|
    t.integer  "day"
    t.integer  "opening_time"
    t.integer  "closing_time"
    t.datetime "created_at",   :null => false
    t.datetime "updated_at",   :null => false
    t.integer  "place_id"
  end

  create_table "photos", :force => true do |t|
    t.string   "reference_id"
    t.integer  "height"
    t.integer  "width"
    t.integer  "place_id"
    t.datetime "created_at",   :null => false
    t.datetime "updated_at",   :null => false
  end

  create_table "places", :force => true do |t|
    t.string   "name"
    t.integer  "price_level"
    t.string   "permanent_id_num"
    t.text     "reference"
    t.string   "address"
    t.decimal  "address_lat"
    t.decimal  "address_lng"
    t.string   "phone_number"
    t.decimal  "rating"
    t.string   "url"
    t.string   "website"
    t.datetime "created_at",       :null => false
    t.datetime "updated_at",       :null => false
    t.text     "review_summary"
    t.decimal  "duration"
    t.integer  "category_id"
  end

  create_table "places_types", :id => false, :force => true do |t|
    t.integer "place_id"
    t.integer "type_id"
  end

  create_table "reviews", :force => true do |t|
    t.string   "author"
    t.text     "text"
    t.string   "author_url"
    t.integer  "time"
    t.decimal  "rating"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
    t.integer  "place_id"
  end

  create_table "types", :force => true do |t|
    t.string   "name"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

end
