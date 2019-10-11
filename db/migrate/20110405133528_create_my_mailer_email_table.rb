class CreateMyMailerEmailTable < ActiveRecord::Migration
  def self.up
    create_table :my_mailer_emails do |emails|
      emails.column :my_mailer_metadata_id, :int
      emails.column :headers, :string
      emails.column :body_attributes, :string
      emails.column :template, :string
      emails.column :priority, :int
      
      emails.timestamps
    end
  end

  def self.down
    drop_table :my_mailer_emails
  end
end
