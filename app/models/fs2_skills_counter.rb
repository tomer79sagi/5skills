class Fs2SkillCounter < ActiveRecord::Base
  
  belongs_to :keywords, :class_name => 'Fs2Keywords', :foreign_key => "keyword_id"
    
end
