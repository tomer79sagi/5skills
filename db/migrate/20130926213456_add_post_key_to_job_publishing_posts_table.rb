class AddPostKeyToJobPublishingPostsTable < ActiveRecord::Migration
  def self.up
    add_column :fs2_job_publishing_posts, :post_key, :string
  end

  def self.down
    remove_column :fs2_job_publishing_posts, :post_key
  end
end
