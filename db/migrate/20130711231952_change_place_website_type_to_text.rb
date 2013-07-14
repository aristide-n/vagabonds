class ChangePlaceWebsiteTypeToText < ActiveRecord::Migration
  def change
    change_column :places, :website, :text
  end
end
