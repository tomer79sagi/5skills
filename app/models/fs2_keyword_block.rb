class Fs2KeywordBlock < ActiveRecord::Base
  
  belongs_to :keywords, :class_name => 'Fs2Keyword', :foreign_key => "keyword_id"
  
  has_many :skill_details, :class_name => 'Fs2SkillDetail', :foreign_key => "skill_id"
  
end
