class CreateUserNotificationsTable < ActiveRecord::Migration
  def self.up
    create_table :fs2_user_notifications do |notify|
      notify.column :user_id, :int
      notify.column :entity_name, :string  # String representing the name of the entity, equivalent to the model (i.e. job, fs_profile etc)
      notify.column :seen_datetime, :datetime
      notify.column :emailed_datetime, :datetime
      
      notify.timestamps
    end
  end

  def self.down
    drop_table :fs2_user_notifications
  end
end
