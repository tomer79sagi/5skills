class AddPrimaryEmailToPeopleTable < ActiveRecord::Migration
  def self.up
    add_column :people, :primary_email, :string    
  end

  def self.down
    remove_column :people, :primary_email
  end
end
