class ConvertJobPublishingPostsFieldsToText < ActiveRecord::Migration
  def self.up
    change_column :fs2_job_publishing_posts, :summary, :text
    change_column :fs2_job_publishing_posts, :content_description, :text
    change_column :fs2_job_publishing_posts, :api_body, :text
  end

  def self.down
    change_column :fs2_job_publishing_posts, :summary, :string
    change_column :fs2_job_publishing_posts, :content_description, :string
    change_column :fs2_job_publishing_posts, :api_body, :string
  end
end
