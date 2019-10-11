class CreateFs2JobApplicationsTable < ActiveRecord::Migration
  def self.up
    create_table :fs2_job_applications do |t|
      t.column :job_seeker_fs_profile_id, :int
      t.column :job_fs_profile_id, :int
      t.column :status_id, :int
      
      t.timestamps
    end
  end

  def self.down
    drop_table :fs2_job_applications
  end
end
