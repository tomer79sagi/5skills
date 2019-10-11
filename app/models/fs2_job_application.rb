class Fs2JobApplication < ActiveRecord::Base
  
  STATUSES = {
    :created => 1,
    :sent => 2
  }
  
  belongs_to :fs2_skills_profiles, :class_name => 'Fs2SkillsProfile', :foreign_key => "job_seeker_fs_profile_id"
  belongs_to :fs2_skills_profiles, :class_name => 'Fs2SkillsProfile', :foreign_key => "job_fs_profile_id"
  
end
