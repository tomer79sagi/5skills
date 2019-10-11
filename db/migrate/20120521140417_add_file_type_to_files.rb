class AddFileTypeToFiles < ActiveRecord::Migration
  def self.up
    add_column :fs2_files, :file_type, :int
  end

  def self.down
    remove_column :fs2_files, :file_type 
  end
end
