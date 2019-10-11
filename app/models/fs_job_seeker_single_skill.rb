class FsJobSeekerSingleSkill < ActiveRecord::Base
  
   belongs_to :fs_job_seeker, :class_name => 'FsJobSeeker', :foreign_key => "fs_job_seeker_id" 
  
end
