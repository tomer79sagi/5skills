class AddStatusToPeopleTable < ActiveRecord::Migration
  def self.up
    add_column :people, :status_id, :int
  end

  def self.down
    remove_column :people, :status_id
  end
end
