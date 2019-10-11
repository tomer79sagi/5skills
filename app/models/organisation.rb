#
# TODO: Check 'organistaion name uniquness' when performing 'quick role or organisation add'
#
# Status_Type:
#  1 - 'Quick' add, only validate presence and uniqueness of name
# *2 - Complete entity (to do, not implemented yet)
#  3 - website identified by a user (need confirmation by the admin) 
#
# Organisation_Type:
#  1 - Agency
#  2 - Company
#  3 - Job Board
#  4 - Social site
#  5 - - Other -
#
class Organisation < ActiveRecord::Base
  # Agent / Company contact association to Agency / Company
  # I have many role_applications by having my foreign_key remotely in role_applications named 'person_id'
  # (matched locally to my 'id') 
  has_many :agency_roles, :class_name => 'Role', :foreign_key => "agency_id"
  has_many :company_roles, :class_name => 'Role', :foreign_key => "company_id"

  has_many :employees, :class_name => 'Person', :foreign_key => "organisation_id"
  #:touch => role_applications_last_updated_at
  
  #has_many :viewing_people, :class_name => 'Person', :through => :person_to_organisations
  #has_many :viewing_people_connections, :class_name => 'PersonToOrganisation', :foreign_key => "organisation_id"
  
  has_many :website_parsing_pages, :class_name => 'WebsiteParsingPage', :foreign_key => "organisation_id"
  
  validates_presence_of :name
  #validates_presence_of :name, :email, :unless => :check_status # As at 30 May 2010
  #validates_length_of :name, :minimum => 1, :message => 'Name ...'
  
  validates_uniqueness_of :name, 
    :message => 'Company already exists with this name, ask to be invited by your colleagues: John ... or choose a different company name',
    :allow_blank => true
  
  validates_uniqueness_of :email, 
    :message => 'Email already exists in database, try "Forgot password" option.',
    :allow_blank => false,
    :unless => :check_status
    
  validates_format_of :email, 
    :with => /^\S+\@(\[?)[A-Za-z0-9\-\.]+\.([A-Za-z]{2,4}|[0-9]{1,4})(\]?)$/ix,
    :message=>"is not a valid e-mail address!",
    :unless => :check_status_email

# --- Currently there is no need for full web-site validation (full = including the 'http://' portion)
#  :with => /^(http|https):\/\/[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,5}(([0-9]{1,5})?\/.*)?$/ix,

  validates_format_of :website, 
    :with => /[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,5}(([0-9]{1,5})?\/.*)?$/ix,
    :message=>"is not a valid website address!",
    :unless => :check_status_website
      
   def check_status_website
     # Either organisation was added 'quickly' or flagged by 'user' that it needs to be added to the system
     return status_id == 1 && website.blank?
   end   
 
   def check_status_email
     return (status_id == 1 || status_id == 3) && email.blank?
   end
 
   def check_status
      return (status_id == 1 || status_id == 3)
  end
  
#  def doX
#    @agent.attributes.each do |key,value|
#      self.attributes[key] = "" if value || value.empty?
#    end
#  end

  def self.organisation_types
      [['- Unknown -', 0],
      ['Company', 1],
      ['Agency', 2], 
      ['Job Board', 3],
      ['Social Site', 4],
      ['- Other -', 5]]
  end
  
  def self.sort_mapping
    {"organisation_name" => "organisation_name"}
  end
  
  def self.agencies_for_select(user_id = nil)
    @sql = "SELECT DISTINCT " +
        "O_Agency.id, " +
        "O_Agency.name " +
      "from " +
        "person_to_organisations PTO, " +
        "organisations O_Agency " +
      "where " +
        "O_Agency.type_id = 1 and " + # 1 = Agency
        "O_Agency.id = PTO.organisation_id "
        
    @sql += "and PTO.person_id = " + user_id.to_s + " " if user_id
    @sql += "order by name asc"
  
    # Get all agencies
    @quick_add_agencies = Organisation.find_by_sql(@sql)    
    @quick_add_agencies = @quick_add_agencies.collect {|agency| [ agency.name, agency.id ]}
    
    # [X, Y] : X = index, Y = length. If legnth is '0', it's INSERT %>
    # Outer '[]' is for array, inner '[]' is for element within array
    @quick_add_agencies[0,0] = [['-- N/A --',0], ["-- New Agency --", -2],['', -1]]
    
    @quick_add_agencies  
  end
  
  def self.companies_for_select(user_id = nil)
    @sql = "SELECT DISTINCT " +
        "O_Company.id, " +
        "O_Company.name " +
      "from " +
        "person_to_organisations PTO, " +
        "organisations O_Company " +
      "where " +
        "O_Company.type_id = 2 and " + # 2 = Company
        "O_Company.id = PTO.organisation_id "
        
    @sql += "and PTO.person_id = " + user_id.to_s + " " if user_id
    @sql += "order by name asc"
  
    # Get all agencies
    @quick_add_companies = Organisation.find_by_sql(@sql)    
    @quick_add_companies = @quick_add_companies.collect {|company| [ company.name, company.id ]}
    
    # [X, Y] : X = index, Y = length. If legnth is '0', it's INSERT %>
    # Outer '[]' is for array, inner '[]' is for element within array
    @quick_add_companies[0,0] = [['-- N/A --',0], ["-- New Company --", -2],['', -1]]
    
    @quick_add_companies
  end
  
end
