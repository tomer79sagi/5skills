class AddPublicProfileUrlToUserNetworkTable < ActiveRecord::Migration
  def self.up
    add_column :fs2_user_connectors, :status_id, :int
    
    add_column :fs2_user_network_connections, :friend_connector_id, :int
  end

  def self.down
    remove_column :fs2_user_network_connections, :friend_connector_id
    
    remove_column :fs2_user_connectors, :status_id
  end
end
