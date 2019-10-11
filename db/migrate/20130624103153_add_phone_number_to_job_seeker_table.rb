class AddPhoneNumberToJobSeekerTable < ActiveRecord::Migration
  def self.up
    add_column :fs2_job_seekers, :phone_number_1, :string
  end

  def self.down
    remove_column :fs2_job_seekers, :phone_number_1
  end
end
