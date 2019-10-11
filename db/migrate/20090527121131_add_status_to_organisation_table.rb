class AddStatusToOrganisationTable < ActiveRecord::Migration
  def self.up
    add_column :organisations, :status_id, :int
  end

  def self.down
    remove_column :organisations, :status_id
  end
end
