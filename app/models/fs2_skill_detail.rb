class Fs2SkillDetail < ActiveRecord::Base
  
  belongs_to :skills, :class_name => 'Fs2Skill', :foreign_key => "skill_id"
  belongs_to :skills_profiles, :class_name => 'Fs2SkillsProfile', :foreign_key => "skills_profile_id"
  belongs_to :keywords, :class_name => 'Fs2Keywords', :foreign_key => "keyword_id"
  
end
