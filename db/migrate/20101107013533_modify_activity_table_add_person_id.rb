class ModifyActivityTableAddPersonId < ActiveRecord::Migration
  def self.up
    add_column :activities, :person_id, :int
  end

  def self.down
    remove_column :activities, :person_id
  end
end
