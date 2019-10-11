class Fs2JobPost < ActiveRecord::Base
  
  TARGETS = {
    :linkedin => 1,
    :facebook => 2,
    :twitter => 3,
    :viadeo => 4,
    :xing => 5
  }
  
  belongs_to :fs2_skills_profiles, :class_name => 'Fs2SkillsProfile', :foreign_key => "job_seeker_fs_profile_id"
  belongs_to :fs2_skills_profiles, :class_name => 'Fs2SkillsProfile', :foreign_key => "job_fs_profile_id"
  
end
