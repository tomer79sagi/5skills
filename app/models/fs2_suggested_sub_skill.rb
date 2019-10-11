class Fs2SuggestedSubSkill < ActiveRecord::Base
  
  belongs_to :primary_skills, :class_name => 'Fs2Keywords', :foreign_key => "primary_skill_id"
  belongs_to :sub_skills, :class_name => 'Fs2Keywords', :foreign_key => "sub_skill_id"
  
end
