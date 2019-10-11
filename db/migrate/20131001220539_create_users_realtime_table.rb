class CreateUsersRealtimeTable < ActiveRecord::Migration
  def self.up
    create_table :fs2_users_realtime do |user_realtime|
      user_realtime.column :user_id, :int
      user_realtime.column :is_online, :boolean
      
      user_realtime.timestamps
    end
  end

  def self.down
    drop_table :fs2_users_realtime
  end
end
