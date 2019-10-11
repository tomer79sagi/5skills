class AddSalaryFrequency < ActiveRecord::Migration
  def self.up
    add_column :roles, :salary_frequency_id, :int
  end

  def self.down
    remove_column :roles, :salary_frequency_id
  end
end
