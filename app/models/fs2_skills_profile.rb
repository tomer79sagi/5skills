class Fs2SkillsProfile < ActiveRecord::Base
  
  belongs_to :job_seekers, :class_name => 'Fs2JobSeeker', :foreign_key => "job_seeker_id"
  
  has_many :skills, :class_name => 'Fs2Skill', :foreign_key => "skills_profile_id", :dependent => :destroy
  has_many :skill_details, :class_name => 'Fs2SkillDetail', :foreign_key => "skills_profile_id", :dependent => :destroy
  has_many :additional_requirements, :class_name => 'Fs2AdditionalRequirement', :foreign_key => "skills_profile_id", :dependent => :destroy
  
  serialize :display_matrix, Array
  
end
