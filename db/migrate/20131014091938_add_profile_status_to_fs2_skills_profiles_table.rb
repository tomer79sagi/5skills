class AddProfileStatusToFs2SkillsProfilesTable < ActiveRecord::Migration
  def self.up
    add_column :fs2_skills_profiles, :profile_status, :int
  end

  def self.down
    remove_column :fs2_skills_profiles, :profile_status
  end
end
