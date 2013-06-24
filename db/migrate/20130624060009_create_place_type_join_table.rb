class CreatePlaceTypeJoinTable < ActiveRecord::Migration
  def change
    create_table :places_types, :id => false do |t|
      t.references :place
      t.references :type
    end
  end
end
