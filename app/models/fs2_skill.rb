class Fs2Skill < ActiveRecord::Base
  
  belongs_to :skills_profiles, :class_name => 'Fs2SkillsProfile', :foreign_key => "skills_profile_id"
  belongs_to :keywords, :class_name => 'Fs2Keyword', :foreign_key => "keyword_id"
  
  has_many :skill_details, :class_name => 'Fs2SkillDetail', :foreign_key => "skill_id"
  
end
