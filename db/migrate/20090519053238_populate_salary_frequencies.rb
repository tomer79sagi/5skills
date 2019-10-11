require 'active_record/fixtures'

class PopulateSalaryFrequencies < ActiveRecord::Migration
  def self.up
    down
    directory = File.join(File.dirname(__FILE__), "data")
    Fixtures.create_fixtures(directory, "salary_frequencies")    
  end

  def self.down
    SalaryFrequency.delete_all
  end
end
