class Fs2MailerEmail < ActiveRecord::Base
  
  serialize :headers, Hash
  serialize :body_attributes, Hash
  
end
