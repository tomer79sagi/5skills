class AddEmailAndProfilePhotoToJobSeekers < ActiveRecord::Migration
  def self.up
    add_column :fs2_job_seekers, :email, :string
    add_column :fs2_job_seekers, :profile_photo_id, :int
  end

  def self.down
    remove_column :email, :fs2_job_seekers
    remove_column :profile_photo_id, :fs2_job_seekers
  end
end
