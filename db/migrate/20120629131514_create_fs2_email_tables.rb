class CreateFs2EmailTables < ActiveRecord::Migration
  def self.up
    create_table :fs2_mailer_actions do |actions|
      actions.column :user_id, :int
      actions.column :controller, :string
      actions.column :action, :string
      actions.column :parameter_ids, :string
      actions.column :parameter_names, :string
      actions.column :parameter_values, :string
      actions.column :email_action_key, :string
    end    
    
    create_table :fs2_mailer_emails do |emails|
      emails.column :headers, :text
      emails.column :body_attributes, :text
      emails.column :template, :string
      emails.column :priority, :int
      
      emails.timestamps
    end
  end

  def self.down
    drop_table :fs2_mailer_emails
    drop_table :fs2_mailer_actions
  end
end
