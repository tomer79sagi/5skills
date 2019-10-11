class CreateCvsToJobsTransactions < ActiveRecord::Migration
  def self.up
    create_table :fs2_cvs_to_jobs_transactions do |transactions|
      transactions.column :job_seeker_id, :int
      transactions.column :job_id, :int
      transactions.column :status_id, :int
      
      transactions.timestamps
    end    
  end

  def self.down
    drop_table :fs2_cvs_to_jobs_transactions
  end
end
