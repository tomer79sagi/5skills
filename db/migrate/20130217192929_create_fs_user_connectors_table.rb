class CreateFsUserConnectorsTable < ActiveRecord::Migration
  def self.up
    
    create_table :fs2_user_connectors do |user_connector|
      user_connector.column :user_id, :int
      user_connector.column :linkedin_access_token, :string
      user_connector.column :linkedin_access_secret, :string
      user_connector.column :linkedin_id, :string
      user_connector.column :linkedin_first_name, :string
      user_connector.column :linkedin_last_name, :string
      user_connector.column :linkedin_public_profile_url, :string
      user_connector.column :linkedin_email, :string
    end
  end

  def self.down
    drop_table :fs2_user_connectors
  end
end
