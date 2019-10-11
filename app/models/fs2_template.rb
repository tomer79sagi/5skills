class Fs2Template < ActiveRecord::Base
  
  belongs_to :skills_profile, :class_name => 'Fs2SkillsProfile', :foreign_key => "skills_profile_id"
  
end
