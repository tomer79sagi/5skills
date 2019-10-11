class AddAdvancedTablesToSkillsProfilesTable < ActiveRecord::Migration
  def self.up
    rename_column :fs2_skills_profiles, :job_seeker_id, :entity_id
    
    add_column :fs2_skills_profiles, :label, :text
    add_column :fs2_skills_profiles, :entity_type, :int
    add_column :fs2_skills_profiles, :profile_type, :int
    
  end

  def self.down
    rename_column :fs2_skills_profiles, :entity_id, :job_seeker_id
    
    remove_column :fs2_skills_profiles, :label
    remove_column :fs2_skills_profiles, :entity_type
    remove_column :fs2_skills_profiles, :profile_type
  end
end