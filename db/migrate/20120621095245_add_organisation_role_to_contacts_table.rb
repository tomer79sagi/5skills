class AddOrganisationRoleToContactsTable < ActiveRecord::Migration
  def self.up
    add_column :fs2_contacts, :organisation_role, :string
  end

  def self.down
    remove_column :fs2_contacts, :organisation_role
  end
end
