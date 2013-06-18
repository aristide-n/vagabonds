class AddPlaceReferenceToEvent < ActiveRecord::Migration
  def change
    change_table :events do |t|
      t.references :place
    end
  end
end
