class AddJobTeaserToFs2JobsTable < ActiveRecord::Migration
  def self.up
    add_column :fs2_jobs, :teaser, :string
  end

  def self.down
    remove_column :fs2_jobs, :teaser
  end
end
