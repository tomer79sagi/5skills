class AddEntityTypeToFs2FilesTable < ActiveRecord::Migration
  def self.up
    add_column :fs2_files, :entity_type_id, :int
  end

  def self.down
    remove_column :fs2_files, :entity_type_id
  end
end
