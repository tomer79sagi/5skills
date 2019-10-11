class CreateSkillsProfilesTable < ActiveRecord::Migration
  def self.up
    rename_column :fs2_skills, :job_seeker_id, :skills_profile_id
    rename_column :fs2_skill_details, :job_seeker_id, :skills_profile_id
    rename_column :fs2_job_seeker_additional_requirements, :job_seeker_id, :skills_profile_id
     
    create_table :fs2_skills_profiles do |skills_profile|
      skills_profile.column :job_seeker_id, :int
      
      skills_profile.timestamps
    end
  end

  def self.down
    rename_column :fs2_skills, :skills_profile_id, :job_seeker_id
    rename_column :fs2_skill_details, :skills_profile_id, :job_seeker_id
    rename_column :fs2_job_seeker_additional_requirements, :skills_profile_id, :job_seeker_id
    
    drop_table :fs2_skills_profiles
  end
end
