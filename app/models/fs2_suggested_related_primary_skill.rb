class Fs2SuggestedRelatedPrimarySkill < ActiveRecord::Base
  
  belongs_to :primary_skills, :class_name => 'Fs2Keywords', :foreign_key => "primary_skill_id"
  belongs_to :related_primary_skills, :class_name => 'Fs2Keywords', :foreign_key => "related_primary_skill_id"
  
end
