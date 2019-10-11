class AddWebsiteParsingFieldType < ActiveRecord::Migration
  def self.up
    add_column :website_parsing_fields, :field_type, :int
    remove_column :website_parsing_fields, :field_name
  end

  def self.down
    remove_column :website_parsing_fields, :field_type
    add_column :website_parsing_fields, :field_name, :string
  end
end
