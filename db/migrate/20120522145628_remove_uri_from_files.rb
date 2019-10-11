class RemoveUriFromFiles < ActiveRecord::Migration
  def self.up
    remove_column :fs2_files, :uri
  end

  def self.down
    add_column :fs2_files, :uri, :string 
  end
end
