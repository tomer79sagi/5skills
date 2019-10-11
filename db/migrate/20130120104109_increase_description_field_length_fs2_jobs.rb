class IncreaseDescriptionFieldLengthFs2Jobs < ActiveRecord::Migration
  def self.up
    change_column :fs2_jobs, :description, :text, :limit => 10000
  end

  def self.down
  end
end
