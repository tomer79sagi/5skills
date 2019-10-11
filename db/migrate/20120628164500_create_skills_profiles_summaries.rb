class CreateSkillsProfilesSummaries < ActiveRecord::Migration
  def self.up
    create_table :fs2_skills_profiles_summaries do |t|
      t.column :js_id, :int
      t.column :js_skills_profile_id, :int
      
      t.column :js_match_points, :int
      t.column :js_match_skills, :string
      t.column :js_match_skills_details, :string
      t.column :js_match_additional_requirements, :string
    end     
  end

  def self.down
    drop_table :fs2_skills_profiles_summaries
  end
end
