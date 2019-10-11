class AddMessageTypeIdToMyMailerMetadatas < ActiveRecord::Migration
  def self.up
    add_column :my_mailer_metadatas, :message_type_id, :int
  end

  def self.down
    remove_column :my_mailer_metadatas, :message_type_id
  end
end
