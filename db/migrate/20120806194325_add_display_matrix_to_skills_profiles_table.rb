class AddDisplayMatrixToSkillsProfilesTable < ActiveRecord::Migration
  def self.up
    add_column :fs2_skills_profiles, :display_matrix, :text
  end

  def self.down
    remove_column :fs2_skills_profiles, :display_matrix
  end
end
