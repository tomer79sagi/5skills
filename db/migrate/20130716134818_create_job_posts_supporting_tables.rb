class CreateJobPostsSupportingTables < ActiveRecord::Migration
  def self.up
    
    # -- SKILL CATEGORIES
    #
    # Sample: "Software developers" <-> "High-tech"
    # 
    create_table :fs2_skill_categories do |skill_categories|
      skill_categories.column :category_name, :string
    end
    
    # -- CATEGORY <-> INDUSTRY
    #
    # Sample: "Software developers" <-> "High-tech"
    # 
    create_table :fs2_map_category_to_industry do |category_industry|
      category_industry.column :category_id, :int
      category_industry.column :industry_id, :int
    end
    
    # -- SKILL <-> CATEGORY
    #
    # Sample: ".NET" <-> "Software developers"
    # 
    create_table :fs2_map_skill_to_category do |skill_category|
      skill_category.column :skill_id, :int
      skill_category.column :skill_category_id, :int
    end
    
    # -- PUBLISHING CHANNELS
    # -- 
    create_table :fs2_publishing_channels do |publishing_channels|
      publishing_channels.column :platform, :string  # For readabilty suring manual SQL querying
      publishing_channels.column :channel_name, :string  # e.g. "Group", "Wall", "Pinterest board"
      publishing_channels.column :channel_id, :string  # i.e. LinkedIn Group id (for retrieval)
      publishing_channels.column :moderated_content_types, :string  # i.e. LinkedIn Group id (for retrieval)
      
      publishing_channels.timestamps
    end 
    
    # -- SKILL / CATEGORY / INDUSTRY <-> PUBLISHING CHANNEL
    #
    # Sample: ".NET" <-> "LinkedIn -> Group -> 232323"
    #  
    create_table :fs2_map_skill_to_publishing_channels do |skill_channel|
      skill_channel.column :industry_id, :int
      skill_channel.column :category_id, :int
      skill_channel.column :skill_id, :int
      skill_channel.column :publishing_channel_id, :int
      
      skill_channel.timestamps
    end
    
    # -- USER <-> PUBLISHING CHANNEL (tracking user status -> permissions, restrictions etc)
    # -- 
    create_table :fs2_map_user_to_publishing_channels do |channels|
      channels.column :user_id, :int
      channels.column :publishing_channel_id, :int
      channels.column :channel_status, :string  # i.e. Group status (Awaiting confirmation)
      
      channels.timestamps
    end 
    
    # -- PUBLISHING POSTS
    # --
    create_table :fs2_job_publishing_posts do |posts|
      posts.column :user_id, :int
      posts.column :job_id, :int
      posts.column :publishing_channel_id, :int
      posts.column :post_type, :string
      posts.column :status, :string  # e.g. 'Published' (5skills status), "Waiting moderation"
      
      posts.column :title, :string
      posts.column :summary, :string
      posts.column :content_submitted_url, :string
      posts.column :content_submitted_image_url, :string
      posts.column :content_title, :string
      posts.column :content_description, :string
      
      posts.column :ref_key, :string  # i.e. Reference for tracking CTRs etc
      posts.column :api_status, :string
      posts.column :api_body, :string  # The body of the message
      
      posts.timestamps
    end
    
    # -- PUBLISHING POST VISITORS
    # --
    create_table :fs2_visitors do |visitors|
      visitors.column :user_id, :string
      visitors.column :source_ip, :string
      visitors.column :source_os, :string
      visitors.column :source_browser, :string
      visitors.column :source_resolution, :string
      
      visitors.column :funnel_id, :int
      visitors.column :funnel_step, :int
    end
    
    # -- PUBLISHING POST VISITORS
    # --
    create_table :fs2_job_publishing_post_visitors do |visitors|
      visitors.column :job_publishing_post_id, :int  # retrieved from the 'ref_key'
      visitors.column :visitor_id, :int
      
      visitors.timestamps
    end
  end

  def self.down
    drop_table :fs2_skill_categories
    drop_table :fs2_map_category_to_industry
    drop_table :fs2_map_skill_to_category
    drop_table :fs2_publishing_channels
    drop_table :fs2_map_skill_to_publishing_channels
    drop_table :fs2_map_user_to_publishing_channels
    
    drop_table :fs2_job_publishing_posts
    drop_table :fs2_visitors
    drop_table :fs2_job_publishing_post_visitors
  end
end
