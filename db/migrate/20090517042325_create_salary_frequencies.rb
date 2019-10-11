class CreateSalaryFrequencies < ActiveRecord::Migration
  def self.up
    create_table :salary_frequencies do |t|
      t.column :name, :string
      t.timestamps
    end
  end

  def self.down
    drop_table :salary_frequencies
  end
end
