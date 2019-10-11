class AddDigestColumnToJobSeekerTable < ActiveRecord::Migration
  def self.up
    add_column :fs_job_seekers, :digest, :string
  end

  def self.down
    remove_column :digest, :fs_job_seekers
  end
end
