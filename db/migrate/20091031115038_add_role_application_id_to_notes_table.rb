class AddRoleApplicationIdToNotesTable < ActiveRecord::Migration
  def self.up
    add_column :notes, :role_application_id, :int
  end

  def self.down
    remove_column :notes, :role_application_id
  end
end
