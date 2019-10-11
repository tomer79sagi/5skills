class AddStatusColumnToFs2JobsTable < ActiveRecord::Migration
  def self.up
    add_column :fs2_jobs, :status_id, :int
  end

  def self.down
    remove_column :fs2_jobs, :status_id
  end
end
