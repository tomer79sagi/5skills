class CreateFeedbackTable < ActiveRecord::Migration
  def self.up
    create_table :feedbacks do |feedbacks|
      
      feedbacks.column :controller, :string
      feedbacks.column :action, :string
      feedbacks.column :my_mailer_metadata_id, :int
      
      feedbacks.timestamps
    end
  end

  def self.down
    drop_table :feedbacks
  end
end
