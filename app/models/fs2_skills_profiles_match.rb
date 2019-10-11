class Fs2SkillsProfilesMatch < ActiveRecord::Base
  
  belongs_to :job_seekers, :class_name => 'Fs2JobSeeker', :foreign_key => "js_id"
  belongs_to :job_seekers_skills_profiles, :class_name => 'Fs2SkillsProfile', :foreign_key => ":js_skills_profile_id"
  
  belongs_to :jobs, :class_name => 'Fs2Job', :foreign_key => "j_id"
  belongs_to :jobs_skills_profiles, :class_name => 'Fs2SkillsProfile', :foreign_key => ":j_skills_profile_id"
  
end
