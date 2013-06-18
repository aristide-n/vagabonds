class ChangePlaceReferenceTypeToText < ActiveRecord::Migration
  def change
    change_column :places, :reference, :text
  end
end
