#
# Field Types:
#  0 - Undefined
#  1 - Job title
#  2 - Job description
#
class WebsiteParsingField < ActiveRecord::Base
  
  belongs_to :website_parsing_page, :class_name => 'WebsiteParsingPage', :foreign_key => "website_parsing_page_id"
  
  validates_presence_of :jquery_css_selector
  
  def self.field_types
      [['Job title', -1],
      ['Job description', -2]]
  end  
    
end
