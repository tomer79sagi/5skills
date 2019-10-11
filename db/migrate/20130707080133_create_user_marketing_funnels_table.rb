class CreateUserMarketingFunnelsTable < ActiveRecord::Migration
  def self.up
    create_table :fs2_user_marketing_funnels do |funnels|
      funnels.column :user_id, :int
      funnels.column :marketing_funnel_id, :int
      funnels.column :state_id, :int
      
      funnels.timestamps
    end    
  end

  def self.down
    drop_table :fs2_user_marketing_funnels
  end
end
