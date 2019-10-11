#
# Need to change the relationship between Role and RoleApplication.
# RoleApplication should hold a Role.id as a Role will have many Role applications
#
class ChangeRoleAndRoleApplicationRelationship < ActiveRecord::Migration
  def self.up
    remove_column :roles, :role_application_id
    add_column :role_applications, :role_id, :int
  end

  def self.down
    add_column :roles, :role_application_id, :int
    remove_column :role_applications, :role_id
  end
end