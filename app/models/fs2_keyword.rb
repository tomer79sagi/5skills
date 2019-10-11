class Fs2Keyword < ActiveRecord::Base
  
  has_many :skills, :class_name => 'Fs2Skill', :foreign_key => "keyword_id"
  has_many :skill_details, :class_name => 'Fs2SkillDetail', :foreign_key => "keyword_id"
  has_many :additional_requirements, :class_name => 'Fs2JobSeekerAdditionalRequirement', :foreign_key => "keyword_id"
  
  has_one :keyword_block, :class_name => 'Fs2KeywordBlock', :foreign_key => "keyword_id"
  
end
