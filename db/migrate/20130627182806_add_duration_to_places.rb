class AddDurationToPlaces < ActiveRecord::Migration
  def change
    add_column :places, :duration, :decimal
  end
end
