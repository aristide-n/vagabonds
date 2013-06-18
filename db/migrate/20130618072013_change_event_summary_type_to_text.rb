class ChangeEventSummaryTypeToText < ActiveRecord::Migration
  def change
    change_column :events, :summary, :text
  end
end
