class MyMailerEmail < ActiveRecord::Base
  
  has_one :email_transaction, :class_name => 'MyMailerEmailTransaction', :foreign_key => "my_mailer_email_id"
  belongs_to :my_mailer_metadata, :class_name => 'MyMailerMetadata', :foreign_key => "my_mailer_metadata_id"
  
  serialize :subject, Hash
  serialize :body, Hash
  
end
