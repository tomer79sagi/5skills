class AddOrganisationRoleToPeopleTable < ActiveRecord::Migration
  def self.up
    add_column :people, :organisation_role, :string
  end

  def self.down
    remove_column :people, :organisation_role
  end
end
