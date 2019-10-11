class CreateSkillsRelated < ActiveRecord::Migration
  
  def self.up
    create_table :fs2_skills_related do |related|
      related.column :skill_id, :int
      related.column :related_skill_id, :int
      related.column :related_strength, :int # strong_rel, some_rel
    end
    
    create_table :fs2_algorithm_weights do |weights|
      weights.column :skill_industry_id, :int
      weights.column :skill_category_id, :int
      weights.column :skill_id, :int
      weights.column :skill_rel_strength, :int # [1] direct [2] strong [3] some
      weights.column :skill_years_exp, :int
      weights.column :skill_priority, :int
    end
    
    create_table :fs2_algorithm_data do |data|
      data.column :fs_profile_id, :int
      data.column :skill_industry_id, :int
      data.column :skill_category_id, :int
      data.column :skill_id, :int
      data.column :skill_rel_strength, :int # [1] direct [2] strong [3] some
      data.column :skill_years_exp, :int
      data.column :skill_priority, :int
    end        
  end

  def self.down
    drop_table :fs2_skills_related
    drop_table :fs2_algorithm_weights
    drop_table :fs2_algorithm_data
  end
  
end
