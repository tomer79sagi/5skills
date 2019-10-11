class Fs2Job < ActiveRecord::Base
  
  STATUS = {
    
    :draft => 1, # Between 'Created' and before a 5skills job profile is VALID (saved but with exceptions)
    :ready_for_publishing => 2, # Once a 5skills job profile is VALID (successfully saved) 
    :published => 3, # Published once or more
    :unpublished => 4, # When the user decides to temporarily or permanently unpublish the job
    :deleted => 0 # Deleted
    
  }
  
  
  belongs_to :skills_profiles, :class_name => 'Fs2SkillsProfile', :foreign_key => "skills_profile_id"
  
  belongs_to :company, :class_name => 'Fs2Organisation', :foreign_key => "company_id"
  belongs_to :agency, :class_name => 'Fs2Organisation', :foreign_key => "agency_id"
  
  belongs_to :company_contact, :class_name => 'Fs2Contact', :foreign_key => "company_contact_id"
  belongs_to :agency_contact, :class_name => 'Fs2Contact', :foreign_key => "agency_contact_id"
  
  
  validates_presence_of :title, :teaser, :location
  
  
end
