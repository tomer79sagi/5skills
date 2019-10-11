class AddDisplayDimensionsToFiles < ActiveRecord::Migration
  def self.up
    add_column :fs2_files, :display_dimensions, :string
  end

  def self.down
    remove_column :fs2_files, :display_dimensions 
  end
end
