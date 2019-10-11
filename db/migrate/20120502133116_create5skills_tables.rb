class Create5skillsTables < ActiveRecord::Migration
  def self.up
    # 'job seekers'
    create_table :fs_job_seekers do |fs_job_seeker|
      
      fs_job_seeker.column :full_name, :string
      fs_job_seeker.column :anonymous, :boolean
      fs_job_seeker.column :looking_for_work, :int # 0 = no, 1 = yes, 2 = yes secretly
      fs_job_seeker.column :additional_requirements, :string
      
      fs_job_seeker.timestamps
    end
    
    # 'job_seeker_single_skills'
    create_table :fs_job_seeker_single_skills do |fs_job_seeker_single_skill|
      
      fs_job_seeker_single_skill.column :priority, :int
      fs_job_seeker_single_skill.column :name, :string
      fs_job_seeker_single_skill.column :years_experience, :int
      fs_job_seeker_single_skill.column :self_rate, :int
      fs_job_seeker_single_skill.column :details, :string
      fs_job_seeker_single_skill.column :digest, :string
      fs_job_seeker_single_skill.column :fs_job_seeker_id, :int
       
      fs_job_seeker_single_skill.timestamps
    end
    
    # 'recruitment_agents'
    create_table :fs_recruitment_agents do |fs_recruitment_agent|
      
      fs_recruitment_agent.column :full_name, :string
      fs_recruitment_agent.column :recruitment_agency_name, :string
      fs_recruitment_agent.column :recruitment_agency_location, :string
      
      fs_recruitment_agent.timestamps
    end
    
    # 'hiring_managers'
    create_table :fs_hiring_managers do |fs_hiring_manager|
      
      fs_hiring_manager.column :full_name, :string
      fs_hiring_manager.column :employer_name, :string
      fs_hiring_manager.column :employer_location, :string
      
      fs_hiring_manager.timestamps
    end
    
    # 'jobs'
    create_table :fs_jobs do |fs_job|
      
      fs_job.column :published, :boolean
      fs_job.column :visible, :boolean
      fs_job.column :additional_requirements, :string
       
      fs_job.timestamps
    end
    
    # 'job_single_skills'
    create_table :fs_job_single_skills do |fs_job_single_skill|
      
      fs_job_single_skill.column :priority, :int
      fs_job_single_skill.column :name, :string
      fs_job_single_skill.column :years_experience, :int
      fs_job_single_skill.column :self_rate, :int
      fs_job_single_skill.column :details, :string
      fs_job_single_skill.column :digest, :string
      fs_job_single_skill.column :fs_job_id, :int
       
      fs_job_single_skill.timestamps
    end
    
    # 'templates'
    create_table :fs_templates do |fs_template|
      
      fs_template.column :name, :string
       
      fs_template.timestamps
    end
    
    # 'template_single_skills'
    create_table :fs_template_single_skills do |fs_template_single_skill|
      
      fs_template_single_skill.column :priority, :int
      fs_template_single_skill.column :name, :string
      fs_template_single_skill.column :years_experience, :int
      fs_template_single_skill.column :self_rate, :int
      fs_template_single_skill.column :details, :string
      fs_template_single_skill.column :digest, :string
      fs_template_single_skill.column :fs_template_id, :int
       
      fs_template_single_skill.timestamps
    end
  end

  def self.down
    drop_table :fs_job_seekers
    drop_table :fs_hiring_managers
    drop_table :fs_jobs
    drop_table :fs_job_seeker_single_skills
    drop_table :fs_job_single_skills
    drop_table :fs_recruitment_agents
    drop_table :fs_templates
    drop_table :fs_template_single_skills
  end
end
