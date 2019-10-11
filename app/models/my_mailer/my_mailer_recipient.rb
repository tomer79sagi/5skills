class MyMailerRecipient < ActiveRecord::Base
  
  belongs_to :mailer_metadata, :class_name => 'MyMailerMetadata', :foreign_key => "my_mailer_metadata_id"
  
end
