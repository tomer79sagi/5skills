class RenameFs2SkillKeywords < ActiveRecord::Migration
  def self.up
    drop_table :fs2_skill_keywords
    
    create_table :fs2_keywords do |fs2_skill_keywords|
      
      fs2_skill_keywords.column :keyword, :string
      
    end
  end

  def self.down
    drop_table :fs2_keywords
    
    create_table :fs2_skill_keywords do |fs2_skill_keywords|
      
      fs2_skill_keywords.column :keyword, :string
      
    end
  end
end
