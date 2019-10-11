class AddSmlDimensionsToFiles < ActiveRecord::Migration
  def self.up
    add_column :fs2_files, :small_dimensions, :string
    add_column :fs2_files, :medium_dimensions, :string
    add_column :fs2_files, :large_dimensions, :string
    
    rename_column :fs2_files, :display_dimensions, :original_dimensions
  end

  def self.down
    remove_column :fs2_files, :small_dimensions
    remove_column :fs2_files, :medium_dimensions
    remove_column :fs2_files, :large_dimensions
    
    rename_column :fs2_files, :original_dimensions, :display_dimensions
  end
end
