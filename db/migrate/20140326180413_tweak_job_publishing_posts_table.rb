class TweakJobPublishingPostsTable < ActiveRecord::Migration
  def self.up
    rename_column :fs2_job_publishing_posts, :api_status, :api_response_code
    rename_column :fs2_job_publishing_posts, :api_body, :api_response_body
    
    add_column :fs2_job_publishing_posts, :api_response_message, :string
  end

  def self.down
    remove_column :fs2_job_publishing_posts, :api_response_message
    
    rename_column :fs2_job_publishing_posts, :api_response_code, :api_status
    rename_column :fs2_job_publishing_posts, :api_response_body, :api_body
  end
end
