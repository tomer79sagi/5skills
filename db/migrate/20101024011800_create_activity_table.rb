class CreateActivityTable < ActiveRecord::Migration
  def self.up
    create_table :activities do |activities|
      activities.column :controller, :string
      activities.column :action, :string
      activities.column :parameters, :string
      activities.column :friendly_names, :string
      
      activities.timestamps
    end
  end

  def self.down
    drop_table :activities
  end
end