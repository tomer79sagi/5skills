class FsJobSeeker < ActiveRecord::Base
  
  # up to 5 skills
  has_many :single_skills, :class_name => 'FsJobSeekerSingleSkill', :foreign_key => "fs_job_seeker_id"
  
end
