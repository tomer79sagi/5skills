class UpdateMyMailerTableSetLongTextForMessageFields < ActiveRecord::Migration
  def self.up
    change_column :my_mailer_messages, :message_html, :longtext
  end

  def self.down
    change_column :my_mailer_messages, :message_html, :string
  end
end
