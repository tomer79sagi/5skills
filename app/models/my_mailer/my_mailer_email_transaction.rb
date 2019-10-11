class MyMailerEmailTransaction < ActiveRecord::Base  
  
  belongs_to :my_mailer_email, :class_name => 'MyMailerEmail', :foreign_key => "my_mailer_email_id"
  
end
