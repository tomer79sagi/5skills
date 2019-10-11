class TweakVisitorsTableFields < ActiveRecord::Migration
  def self.up
    rename_column :fs2_visitors, :source_ip, :ip
    rename_column :fs2_visitors, :source_os, :referrer
    rename_column :fs2_visitors, :source_browser, :agent
    
    remove_column :fs2_visitors, :source_resolution
  end

  def self.down
    rename_column :fs2_visitors, :ip, :source_ip
    rename_column :fs2_visitors, :referrer, :source_os
    rename_column :fs2_visitors, :agent, :source_browser
    
    add_column :fs2_visitors, :source_resolution, :string
  end
end
