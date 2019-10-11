class RenameAdditionalRequirementsTable < ActiveRecord::Migration
    def self.up
        rename_table :fs2_job_seeker_additional_requirements, :fs2_additional_requirements
    end 
    def self.down
        rename_table :fs2_additional_requirements, :fs2_job_seeker_additional_requirements
    end
end
