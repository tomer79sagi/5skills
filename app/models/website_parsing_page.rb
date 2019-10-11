#
# Page Types:
#  0 - Unknown
#  1 - Search results page
#  2 - Job ad page
#  3 - Apply page
#
class WebsiteParsingPage < ActiveRecord::Base
  
  belongs_to :organisation, :class_name => 'Organisation', :foreign_key => "organisation_id"
  
  has_many :website_parsing_fields, :class_name => 'WebsiteParsingField', :foreign_key => "website_parsing_page_id"
  
  validates_presence_of :uri_string
  
  def self.page_types
    [['- Unknown -', 0],
      ['Search results page', 1],
      ['Job ad page', 2],
      ['Apply page', 3]]
  end    
    
end