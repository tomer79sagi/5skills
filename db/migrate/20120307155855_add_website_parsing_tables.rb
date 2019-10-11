class AddWebsiteParsingTables < ActiveRecord::Migration
  def self.up
    
    # Website parsing FIELDS 
    create_table :website_parsing_fields do |fields|
      fields.column :organisation_id, :int
      fields.column :field_name, :string
      fields.column :jquery_css_selector, :string
    end
    
    # Website parsing PAGES
    create_table :website_parsing_pages do |pages|
      pages.column :organisation_id, :int
      pages.column :uri_string, :string
      pages.column :page_type, :int
    end
    
  end

  def self.down
    drop_table :website_parsing_fields
    drop_table :website_parsing_pages
  end
end
