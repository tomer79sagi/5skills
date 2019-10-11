class AddPageTypeToFieldsTable < ActiveRecord::Migration
  def self.up
    add_column :website_parsing_fields, :page_type, :int
  end

  def self.down
    remove_column :website_parsing_fields, :page_type
  end
end
