class AddStatusIdToRoleApplicationsTable < ActiveRecord::Migration
  def self.up
    add_column :role_applications, :status_id, :int
  end

  def self.down
    remove_column :role_applications, :status_id
  end
end
