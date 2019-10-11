class AddPersonPasswordToMessageTable < ActiveRecord::Migration
  def self.up
    add_column :messages, :person_password, :string
  end

  def self.down
    remove_column :messages, :person_password
  end
end
