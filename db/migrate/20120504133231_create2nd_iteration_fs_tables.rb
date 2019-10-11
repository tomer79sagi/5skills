class Create2ndIterationFsTables < ActiveRecord::Migration
  def self.up
    # 'job seekers'
    create_table :fs2_job_seekers do |fs_job_seeker|
      
      fs_job_seeker.column :full_name, :string
      fs_job_seeker.column :anonymous, :boolean # 0 = no, 1 = yes
      fs_job_seeker.column :looking_for_work, :boolean # 0 = no, 1 = yes
      
      fs_job_seeker.timestamps
    end
    
    create_table :fs2_skills do |fs_job_seeker_single_skill|
      
      fs_job_seeker_single_skill.column :job_seeker_id, :int
      fs_job_seeker_single_skill.column :priority, :int
      fs_job_seeker_single_skill.column :keyword_id, :int
      fs_job_seeker_single_skill.column :years_experience, :int
      fs_job_seeker_single_skill.column :self_rate, :int
       
      fs_job_seeker_single_skill.timestamps
    end

    create_table :fs2_skill_details do |fs2_skill_details|
      
      fs2_skill_details.column :skill_id, :int
      fs2_skill_details.column :job_seeker_id, :int
      fs2_skill_details.column :priority, :int
      fs2_skill_details.column :keyword_id, :int
       
      fs2_skill_details.timestamps
    end
    
    create_table :fs2_job_seeker_additional_requirements do |fs2_job_seeker_additional_requirements|
      
      fs2_job_seeker_additional_requirements.column :job_seeker_id, :int
      fs2_job_seeker_additional_requirements.column :priority, :int
      fs2_job_seeker_additional_requirements.column :keyword_id, :int
       
      fs2_job_seeker_additional_requirements.timestamps
    end
  end

  def self.down
    drop_table :fs2_job_seekers
    drop_table :fs2_skills
    drop_table :fs2_skill_details
    drop_table :fs2_job_seeker_additional_requirements
  end
end
