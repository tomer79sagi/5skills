class ChangeCookieTimeAttributeInPersonTableFromStringToDate < ActiveRecord::Migration
  def self.up
    remove_column :people, :remember_token_expires
    #TODO: Need to test 'datetime' creates a 'datetime' field in the database
    add_column :people, :remember_token_expires, :datetime
  end

  def self.down
    add_column :people, :remember_token_expires, :string
    remove_column :people, :remember_token_expires
  end
end
