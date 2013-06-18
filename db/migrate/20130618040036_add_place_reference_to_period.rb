class AddPlaceReferenceToPeriod < ActiveRecord::Migration
  def change
    change_table :periods do |t|
      t.references :place
    end
  end
end
