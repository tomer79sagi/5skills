class AddAnonymousFieldsToJobSeekerTable < ActiveRecord::Migration
  def self.up
    add_column :fs2_job_seekers, :full_name_secret, :string
    add_column :fs2_job_seekers, :profile_photo_id_secret, :int
  end

  def self.down
    remove_column :fs2_job_seekers, :full_name_secret
    remove_column :fs2_job_seekers, :profile_photo_id_secret
  end
end
