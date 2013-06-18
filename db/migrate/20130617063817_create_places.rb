class CreatePlaces < ActiveRecord::Migration
  def change
    create_table :places do |t|
      t.string :name
      t.integer :price_level
      t.string :permanent_id_num
      t.string :reference
      t.string :address
      t.decimal :address_lat
      t.decimal :address_lng
      t.string :phone_number
      t.decimal :rating
      t.string :url
      t.string :website

      t.timestamps
    end
  end
end
