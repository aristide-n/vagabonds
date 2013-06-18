class CreateCategoryPlaceJoinTable < ActiveRecord::Migration
  def change
    create_table :categories_places, :id => false do |t|
      t.references :category
      t.references :place
    end
  end
end
