class AddGroupDetailsToPublishingChannelsTable < ActiveRecord::Migration
  def self.up
    rename_column :fs2_publishing_channels, :channel_name, :channel_type
    
    add_column :fs2_publishing_channels, :channel_name, :string
    add_column :fs2_publishing_channels, :short_description, :string
    add_column :fs2_publishing_channels, :website_url, :string
    add_column :fs2_publishing_channels, :site_group_url, :string
    add_column :fs2_publishing_channels, :small_logo_url, :string
    add_column :fs2_publishing_channels, :large_logo_url, :string
    add_column :fs2_publishing_channels, :num_members, :int
  end

  def self.down
    rename_column :fs2_publishing_channels, :channel_type, :channel_name
    
    remove_column :fs2_publishing_channels, :channel_name
    remove_column :fs2_publishing_channels, :short_description
    remove_column :fs2_publishing_channels, :website_url
    remove_column :fs2_publishing_channels, :site_group_url
    remove_column :fs2_publishing_channels, :small_logo_url
    remove_column :fs2_publishing_channels, :large_logo_url
    remove_column :fs2_publishing_channels, :num_members
  end
end
