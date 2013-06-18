class CreateEvents < ActiveRecord::Migration
  def change
    create_table :events do |t|
      t.integer :id_num
      t.string :summary
      t.string :url
      t.integer :start_time

      t.timestamps
    end
  end
end
