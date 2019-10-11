class ModifyPeopleTableAddSalt < ActiveRecord::Migration
  def self.up
    add_column :people, :salt, :string
    add_column :people, :hashed_password, :string
    
    Person.reset_column_information
  end

  def self.down
    remove_column :people, :salt
    remove_column :people, :hashed_password
  end
end
