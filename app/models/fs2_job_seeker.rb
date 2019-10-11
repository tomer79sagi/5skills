class Fs2JobSeeker < ActiveRecord::Base
  
  attr_accessible :phone_number_1, :full_name, :user_id
  
  has_many :skills_profiles, :class_name => 'Fs2SkillsProfile', :foreign_key => "job_seeker_id"
  
  validates_presence_of :full_name
  validates_presence_of :phone_number_1
  
end
