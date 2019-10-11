class AddSalaryFieldsToRoles < ActiveRecord::Migration
  def self.up
    add_column :roles, :salary_min, :float
    add_column :roles, :salary_max, :float
  end

  def self.down
    remove_column :roles, :salary_min
    remove_column :roles, :salary_max
  end
end