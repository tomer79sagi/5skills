class AddStatusIdToMailerMetadatasAndRecipients < ActiveRecord::Migration
  def self.up
    add_column :my_mailer_metadatas, :message_status_id, :int
    add_column :my_mailer_recipients, :message_status_id, :int
  end

  def self.down
    remove_column :my_mailer_metadatas, :message_status_id
    remove_column :my_mailer_recipients, :message_status_id
  end
end
