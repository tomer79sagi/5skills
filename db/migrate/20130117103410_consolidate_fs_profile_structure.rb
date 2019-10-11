class ConsolidateFsProfileStructure < ActiveRecord::Migration
  def self.up
    
    
    # --- JOB SEEKERS
    
    job_seekers = Fs2JobSeeker.find(:all)
    
    job_seekers.each do |job_seeker|
        Fs2SkillsProfile.connection.execute("update fs2_skills_profiles set" +
          " entity_type = 2" +
          ", profile_type = 1" + 
          " where entity_id = " + job_seeker.id.to_s)
    end
    
    
    
    # --- JOBS
    
    jobs = Fs2Job.find(:all)
    
    jobs.each do |job|
      if job.skills_profile_id
        Fs2SkillsProfile.connection.execute("update fs2_skills_profiles set" +
          " entity_id = " + job.id.to_s + 
          ", entity_type = 1" +
          ", profile_type = 1" + 
          " where id = " + job.skills_profile_id.to_s)
      end
    end
    
    remove_column :fs2_jobs, :skills_profile_id
    
  end

  def self.down
  end
end
