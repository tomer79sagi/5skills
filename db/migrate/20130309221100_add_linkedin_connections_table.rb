class AddLinkedinConnectionsTable < ActiveRecord::Migration
  def self.up
    create_table :fs2_user_network_connections do |connection|
      connection.column :user_connector_id, :int
      connection.column :friend_linkedin_id, :string
    end  
  end

  def self.down
    drop_table :fs2_user_network_connections
  end
end
