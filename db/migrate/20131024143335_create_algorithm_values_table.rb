class CreateAlgorithmValuesTable < ActiveRecord::Migration
  def self.up
    rename_table :fs2_algorithm_data, :fs2_algorithm_handles
    
    create_table :fs2_algorithm_values do |value|
      value.column :fs_profile_id, :int
      
      value.column :skill_industry_id, :int
      value.column :skill_industry_name, :string
      
      value.column :skill_category_id, :int
      value.column :skill_category_name, :string
      
      value.column :skill_id, :int
      value.column :skill_name, :string
      value.column :skill_years_exp, :int
      value.column :skill_priority, :int
    end 
  end

  def self.down
    rename_table :fs2_algorithm_handles, :fs2_algorithm_data
    
    drop_table :fs2_algorithm_values
  end
end
