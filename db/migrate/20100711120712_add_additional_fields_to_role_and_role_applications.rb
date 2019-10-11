class AddAdditionalFieldsToRoleAndRoleApplications < ActiveRecord::Migration
  def self.up
    add_column :roles, :duration, :int
    add_column :roles, :duration_type_id, :int
    add_column :roles, :location_id, :int
    add_column :roles, :start_date, :date
    add_column :roles, :external_link, :string
  end

  def self.down
    remove_column :roles, :duration 
    remove_column :roles, :duration_type_id
    remove_column :roles, :location_id
    remove_column :roles, :start_date
    remove_column :roles, :external_link 
  end
end
