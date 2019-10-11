class CreateUsersTable < ActiveRecord::Migration
  def self.up
    
    create_table :fs2_users do |t|
      t.column :email, :string
      
      t.column :password, :string
      t.column :salt, :string
      t.column :hashed_password, :string
      
      t.column :remember_token, :string
      t.column :remember_token_expires, :datetime
      
      t.column :status_id, :int
      t.column :user_type_id, :int
    
      t.timestamps
    end
    
    add_column :fs2_job_seekers, :user_id, :int
    add_column :fs2_contacts, :user_id, :int
    
    remove_column :fs2_job_seekers, :email
    remove_column :fs2_contacts, :email
    
  end

  def self.down
    drop_table :fs2_users
    
    remove_column :fs2_job_seekers, :user_id
    remove_column :fs2_contacts, :user_id
    
    add_column :fs2_job_seekers, :email, :string
    add_column :fs2_contacts, :email, :string
  end
end