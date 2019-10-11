class MessageForm < ActiveForm
  attr_accessor :body, :sender_name, :sender_email
  
  validates_presence_of :body, :sender_name, :sender_email
  
  validates_format_of :sender_email, 
    :with => /^\S+\@(\[?)[A-Za-z0-9\-\.]+\.([A-Za-z]{2,4}|[0-9]{1,4})(\]?)$/ix,
    :message=>"is not a valid e-mail address!"
end