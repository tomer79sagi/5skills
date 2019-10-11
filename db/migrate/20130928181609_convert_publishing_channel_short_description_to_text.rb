class ConvertPublishingChannelShortDescriptionToText < ActiveRecord::Migration
  def self.up
    change_column :fs2_publishing_channels, :short_description, :text
  end

  def self.down
    change_column :fs2_publishing_channels, :short_description, :string
  end
end
