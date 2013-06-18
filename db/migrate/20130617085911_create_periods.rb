class CreatePeriods < ActiveRecord::Migration
  def change
    create_table :periods do |t|
      t.integer :day
      t.integer :opening_time
      t.integer :closing_time

      t.timestamps
    end
  end
end
