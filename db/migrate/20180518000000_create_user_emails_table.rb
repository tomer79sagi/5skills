class CreateUserEmailsTable < ActiveRecord::Migration
  def self.up
    create_table :email_users do |email_users|
      email_users.column :email, :string
      email_users.column :phone, :string
      email_users.column :status, :int
      
      email_users.timestamps
    end
  end

  def self.down
    drop_table :email_users
  end
end
