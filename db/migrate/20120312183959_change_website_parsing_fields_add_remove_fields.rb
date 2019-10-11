class ChangeWebsiteParsingFieldsAddRemoveFields < ActiveRecord::Migration
  def self.up
     rename_column :website_parsing_fields, :organisation_id, :website_parsing_page_id
     remove_column :website_parsing_fields, :page_type
  end

  def self.down
    rename_column :website_parsing_fields, :website_parsing_page_id, :organisation_id 
    add_column :website_parsing_fields, :page_type, :int
  end
end
