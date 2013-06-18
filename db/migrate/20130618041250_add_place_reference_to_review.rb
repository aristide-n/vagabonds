class AddPlaceReferenceToReview < ActiveRecord::Migration
  def change
    change_table :reviews do |t|
      t.references :place
    end
  end
end
