class PlacesCategoryAssociations < ActiveRecord::Migration
  def up
    add_column :places, :category_id, :integer
  end

  def down
    drop_table :categories_places
  end
end
