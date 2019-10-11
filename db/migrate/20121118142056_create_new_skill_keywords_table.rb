class CreateNewSkillKeywordsTable < ActiveRecord::Migration
  def self.up
    remove_column :fs2_keywords, :suggest_as_primary
    remove_column :fs2_keywords, :type_id
    add_column :fs2_keywords, :replace_with_skill_id, :int
    
    create_table :fs2_skill_keywords do |skill_keywords|
      skill_keywords.column :en_US, :string
      skill_keywords.column :suggest_as_primary, :boolean
      skill_keywords.column :type_id, :int
    end
  end

  def self.down
    remove_column :replace_with_skill_id, :int
    add_column :fs2_keywords, :suggest_as_primary, :boolean
    add_column :fs2_keywords, :type_id, :int
    
    drop_table :fs2_skill_keywords
  end
end
