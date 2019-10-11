class AddCookieAttributesToPersonTable < ActiveRecord::Migration
  def self.up
    add_column :people, :remember_token, :string
    add_column :people, :remember_token_expires, :string
  end

  def self.down
    remove_column :people, :remember_token
    remove_column :people, :remember_token_expires    
  end
end
