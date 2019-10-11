class AddParentMessageIdToMailerMetadatasTable < ActiveRecord::Migration
  def self.up
    add_column :my_mailer_metadatas, :parent_message_id, :int
  end

  def self.down
    remove_column :my_mailer_metadatas, :parent_message_id
  end
end
