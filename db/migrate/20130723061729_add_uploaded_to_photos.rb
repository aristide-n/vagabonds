class AddUploadedToPhotos < ActiveRecord::Migration
  def self.up
    add_attachment :photos, :uploaded
  end

  def self.down
    remove_attachment :photos, :uploaded
  end
end
