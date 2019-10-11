class CreateAdvancedSkillsTables < ActiveRecord::Migration
  def self.up
    add_column :fs2_keywords, :suggest_as_primary, :boolean
    add_column :fs2_keywords, :type_id, :int
    
    create_table :fs2_keyword_blocks do |blocks|
      blocks.column :keyword_id, :int
      blocks.column :blocked, :boolean
      blocks.column :readon_id, :int
      blocks.column :replace_id, :int
    end    
    
    create_table :fs2_suggested_sub_skills do |sub_skills|
      sub_skills.column :primary_skill_id, :int
      sub_skills.column :sub_skill_id, :int
    end
    
    create_table :fs2_suggested_related_primary_skills do |related_primary_skills|
      related_primary_skills.column :primary_skill_id, :int
      related_primary_skills.column :related_primary_skill_id, :int
    end
    
    create_table :fs2_skills_counters do |skills_counters|
      skills_counters.column :keyword_id, :int
      skills_counters.column :total, :int
      skills_counters.column :as_primary, :int
      skills_counters.column :as_primary_skill_1, :int
      skills_counters.column :as_primary_skill_2, :int
      skills_counters.column :as_primary_skill_3, :int
      skills_counters.column :as_primary_skill_4, :int
      skills_counters.column :as_primary_skill_5, :int
      skills_counters.column :as_secondary_skill_1, :int
      skills_counters.column :as_secondary_skill_2, :int
      skills_counters.column :as_secondary_skill_3, :int
      skills_counters.column :as_secondary_skill_4, :int
      skills_counters.column :as_secondary_skill_5, :int
    end
  end

  def self.down
    remove_column :fs2_keywords, :suggest_as_primary
    remove_column :fs2_keywords, :type_id
    
    drop_table :fs2_keyword_blocks
    drop_table :fs2_suggested_sub_skills
    drop_table :fs2_suggested_related_primary_skills
    drop_table :fs2_skills_counters
  end
end
