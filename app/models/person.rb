# Person_Type:
#  0 - Website role (e.g. admin, support etc)
#  1 - Candidate
#  2 - Agent
#  3 - Company Contact
#
# Status:
#  1 - New
#  2 - Registered
#  3 - Confirmed : email confirmed
#  4 - Must change password
#
class Person < ActiveRecord::Base
  # Agent / Company contact association to Agency / Company
  # I have a local foreign_key named 'organisation_id' to find the Organisation I belong to (Agency or Company)
  # (matched remotely to the Organisation's 'id')
  
  belongs_to :my_organisation, :class_name => 'Organisation', :foreign_key => "organisation_id"
  
  #TODO: Uncomment when auto-association works fine (currently not working on my machine)
  #has_many :personal_organisations, :class_name => 'Organisation', :through => :person_to_organisations
  #has_many :personal_organisation_connections, :class_name => 'PersonToOrganisation', :foreign_key => "person_id"
    
  has_many :job_applications, :class_name => 'RoleApplication', :foreign_key => "person_id"
  
  has_one :email_confirmation
 
  #has_many :organisations, :through => :person_to_organisations
  
  validates_presence_of :first_name
  validates_presence_of :last_name, :primary_email, :password, :unless => :check_status
  
  validates_uniqueness_of :primary_email, 
    :message => 'Email already exists in database, try "Forgot password" option.',
    :allow_blank => false,
    :unless => :check_status
      
  validates_format_of :primary_email, 
    :with => /^\S+\@(\[?)[A-Za-z0-9\-\.]+\.([A-Za-z]{2,4}|[0-9]{1,4})(\]?)$/ix,
    :message=>"is not a valid e-mail address!",
    :unless => :check_status_email

  validates_format_of :website, 
    :with => /^(http|https):\/\/[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,5}(([0-9]{1,5})?\/.*)?$/ix,
    :message=>"is not a valid website address!",
    :unless => :check_status_website
      
  validates_presence_of :password_confirmation, :if => :password_changed?
  validates_confirmation_of :password, :on => :create, :message => "should match confirmation"
  validates_length_of :password, :within => 7..9, :unless => :check_status
  
  # These lines ensure that that password will be hashed once it's changed
  # 1. Hashing the password before a comprehensive 'save'
  # 2. Hashing the password after a 'quick' update action
  before_save :hash_new_password, :if => :password_changed?
  after_update :hash_new_password, :if => :password_changed?
    
   # If a user matching the credentials is found, returns the User object.
   # If no matching user is found, returns nil.
   def self.authenticate(user_info)
     @user = find_by_primary_email(user_info[:email])
     
     #TODO:Need to return 'hash'-based password check. Got stuck and can't be FUCKED fixing it right now
     return @user if @user && user_info[:password] == @user.password
#     return @user if @user.hashed_password == Digest::SHA2.hexdigest(@user.salt + user_info[:password])
     
     return nil
   end
   
   def check_status_website
     return (status_id == 1 || status_id == 2) && website.blank?
   end   
 
   def check_status_email
     return status_id == 1 && primary_email.blank?
   end
 
   def check_status
      return status_id == 1
  end
  
  def hash_new_password
    # This logic is copied to migration "20110202133134" for hashing existing passwords of 
    # already registered users
    
    # This logic is copied to the Person model for registration of new people
    @salt = ActiveSupport::SecureRandom.base64(8)
      
    self.salt = @salt
    self.hashed_password = Digest::SHA2.hexdigest(@salt + self.password)
    self.password = "{hashed}"
  end
  
  def remember_me
    self.remember_token_expires = 1.minute.from_now
    self.remember_token = Digest::SHA1.hexdigest("#{self.primary_email}--#{self.remember_token_expires}")
    #self.password = ""  # This bypasses password encryption, thus leaving password intact
    self.save_with_validation(false)
  end

  def forget_me
    self.remember_token_expires = nil
    self.remember_token = nil
    #self.password = ""  # This bypasses password encryption, thus leaving password intact
    self.save_with_validation(false)
  end  
end
