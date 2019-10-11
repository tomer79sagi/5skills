class CreateSkillsProfilesMatches < ActiveRecord::Migration
  def self.up
    create_table :fs2_skills_profiles_matches do |t|
      t.column :js_id, :int
      t.column :js_skills_profile_id, :int
      t.column :js_match_status, :int
      
      t.column :j_id, :int
      t.column :j_skills_profile_id, :int
      t.column :j_match_status, :int
      
      t.column :match_date, :datetime
      t.column :match_points, :int
      t.column :match_skills, :string
      t.column :match_skills_details, :string
      t.column :match_additional_requirements, :string
    end    
  end

  def self.down
    drop_table :fs2_skills_profiles_matches
  end
end
