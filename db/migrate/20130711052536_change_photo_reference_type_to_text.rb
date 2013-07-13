class ChangePhotoReferenceTypeToText < ActiveRecord::Migration
  def change
    change_column :photos, :reference_id, :text
  end
end
