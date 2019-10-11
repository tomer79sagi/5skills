class AddUserReferralColumn < ActiveRecord::Migration
  def self.up
    add_column :fs2_users, :referral_id, :int
  end

  def self.down
    remove_column :fs2_users, :referral_id
  end
end
