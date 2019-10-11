class FsJobSeeker < ActiveRecord::Base
  
  # up to 5 skills
  has_many :fs_job_seeker_single_skill, :class_name => 'FsJobSeekerSingleSkill', :foreign_key => "fs_job_seeker_id"
  
end
