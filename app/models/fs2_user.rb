#
# STATUS:
#  1 - New
#  2 - Registered
#  3 - Confirmed : email confirmed
#  4 - Must change password
#
# USER_TYPE:
#  1 - Job Seeker
#  2 - Recruitment Agent
#  3 - Hiring Manager
#
class Fs2User < ActiveRecord::Base
  
  VALIDATION_MESSAGES = {
    :already_exists => 'is already registered!'
  }
  
  USER_TYPES = {:job_seeker => 1, :recruitment_agent => 2, :hiring_manager => 3, :recruiter => 9, :joint_js_rec => 11}
  
  USER_REFERRALS = {
    :unknown => -1,
    :non_campaign => 0,
    :campaign_1_email_invite_1 => 1,
    :campaign_1_email_invite_2 => 2,
    :linkedin_job_post => 3,
    
    :added_through_friend => 101
  }
  
  USER_STATUSES = {
    
    :scraped => 51,
     
    :at_landing_page => 100,
    :linkedin_signed_in => 102,  
    :completed_3_skills => 105, 
    :hit_apply_pre_registration => 110, 
    :registered => 114,
    :applied_once => 117,
    :sent_cv_once => 120,
    :registration_confirmed => 125,
    :must_change_password => 130,
    
    # recruitment agent statuses
    :recruitment_agent__registered => 201
  }
  
  belongs_to :fs2_job_seekers, :class_name => 'Fs2JobSeeker', :foreign_key => "user_id"
  belongs_to :fs2_contacts, :class_name => 'Fs2Contact', :foreign_key => "user_id"
  
  before_save :hash_new_password, :if => :password_changed?
  after_update :hash_new_password, :if => :password_changed?
  
  validates_presence_of :email
  validates_presence_of :password, :unless => :is_lead?
  
  
  # --- June 2013 deployment note ---
  #   Having differences between development and production environments re: checking duplicate records
  #   For now, it's ignored
  # --------------------------------
  # validates_uniqueness_of :email, 
    # :message => VALIDATION_MESSAGES[:already_exists],
    # :allow_blank => true
      
  validates_format_of :email, 
    :with => /^\S+\@(\[?)[A-Za-z0-9\-\.]+\.([A-Za-z]{2,4}|[0-9]{1,4})(\]?)$/ix,
    :message=>"is not a valid e-mail address!",
    :allow_blank => true
  
  validates_format_of :password, 
    :with => /(?=.*\d)(?=.*[a-z])(?=.*[A-Z]).{6}/ix,
    :message=>"is not a valid password!", 
    :unless => :is_lead?
    
  def self.authenticate(user_info)
    @user = find_by_email(user_info[:email])
   
    return nil if @user.nil?
     
    #TODO:Need to return 'hash'-based password check. Got stuck and can't be FUCKED fixing it right now
#     return @user if @user && user_info[:password] == @user.password
    return @user if @user.hashed_password == Digest::SHA2.hexdigest(@user.salt + user_info[:password])
   
    return nil
  end
  
  def is_lead?
    self.status_id == USER_STATUSES[:mvp_lead]
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
