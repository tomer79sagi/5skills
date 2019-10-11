class Feedback < ActiveRecord::Base  
  
  belongs_to :my_mailer_metadata, :class_name => 'MyMailerMetadata', :foreign_key => "my_mailer_metadata_id"
  
end
