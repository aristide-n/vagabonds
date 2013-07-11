class CreatePhotos < ActiveRecord::Migration
  def change
    create_table :photos do |t|
      t.string :reference_id
      t.integer :height
      t.integer :width

      t.references :place
      t.timestamps
    end
  end
end
