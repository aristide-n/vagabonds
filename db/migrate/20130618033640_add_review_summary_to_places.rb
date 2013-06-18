class AddReviewSummaryToPlaces < ActiveRecord::Migration
  def change
    add_column :places, :review_summary, :text
  end
end
