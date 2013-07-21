class ChangePlaceAddressTypeToText < ActiveRecord::Migration
  def change
    change_column :places, :address, :text
  end
end
