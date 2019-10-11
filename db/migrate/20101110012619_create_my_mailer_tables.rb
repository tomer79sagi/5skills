class CreateMyMailerTables < ActiveRecord::Migration
  def self.up
    create_table :my_mailer_metadatas do |metadata|
      metadata.column :sender_id, :int
      metadata.column :subject, :string
      metadata.column :message_summary, :string
      
      metadata.timestamps
    end
    
    create_table :my_mailer_recipients do |recipients|
      recipients.column :my_mailer_metadata_id, :int
      recipients.column :recipient_id, :int
    end
    
    create_table :my_mailer_messages do |messages|
      messages.column :my_mailer_metadata_id, :int
      messages.column :message_html, :string
    end
  end

  def self.down
    drop_table :my_mailer_metadatas
    drop_table :my_mailer_recipients
    drop_table :my_mailer_messages
  end
end