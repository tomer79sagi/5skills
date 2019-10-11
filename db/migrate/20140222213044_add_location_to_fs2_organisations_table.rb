class AddLocationToFs2OrganisationsTable < ActiveRecord::Migration
  def self.up
    add_column :fs2_jobs, :location, :string
  end

  def self.down
    remove_column :fs2_jobs, :location
  end
end
