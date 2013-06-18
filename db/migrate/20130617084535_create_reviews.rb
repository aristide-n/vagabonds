class CreateReviews < ActiveRecord::Migration
  def change
    create_table :reviews do |t|
      t.string :author
      t.string :text
      t.string :author_url
      t.integer :time
      t.decimal :rating

      t.timestamps
    end
  end
end
