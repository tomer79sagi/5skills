class AddConfirmationEmailParamToMessageTable < ActiveRecord::Migration
  def self.up
    add_column :messages, :confirmation_email_key, :string
  end

  def self.down
    remove_column :messages, :confirmation_email_key
  end
end
