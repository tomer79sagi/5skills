class Fs2Mailer < ActionMailer::Base
  
  EMAIL_TYPES = {
    :new_job_matches => 1, 
    :new_job_seeker_matches => 2,
    :cv_sent_for_job => 3,
    :cv_requested_for_job => 4,
    :cv_request_rejected_for_job => 5,
    :cv_request_approved_for_job => 6,
    :apply_from_social_job_post => 7}
    
  EMAIL_EXCHANGE_TYPES = {
    :user_to_admin => 1,
    :admin_to_user => 2,
    :system_to_admin => 3,
    :system_to_job_seeker => 4,
    :system_to_recruitment_agent => 5,
    :system_to_hiring_manager => 6,
    :user_to_system => 7}
  
#  def new_job_matches_email(message_h, attributes_h, sent_at = Time.now)
#    new_email(message_h, attributes_h)
#  end
#  
#  def new_job_seeker_matches_email(message_h, attributes_h, sent_at = Time.now)
#    new_email(message_h, attributes_h)
#  end
#  
#  def new_email(message_h, attributes_h, sent_at = Time.now)
#    @from = message_h["sender"]
#    @recipients = message_h["recipients"]
#    @subject = message_h["subject"]
#    @reply_to = message_h["reply_to"]
#    @sent_on = sent_at
#    @headers = {}
#    
#    @body = attributes_h if attributes_h
#  end
  
  def init(message_h, attributes_h, template_s, sent_at = Time.now)
    
    @from = message_h["sender"]
    @recipients = message_h["recipients"]
    @subject = message_h["subject"]
    @reply_to = message_h["reply_to"]
    @sent_on = sent_at
    @headers = {}
    
    if attributes_h["attachments"]
      attributes_h["attachments"].each do |file_id, file_obj_h|
        attachment file_obj_h[:mime_type] do |a|
          a.body = File.read(RAILS_ROOT + "/" + file_obj_h[:path])
          a.filename = file_obj_h[:name]
        end
      end
    end
    
    # Need to ensure the following template exists in the 'views/my_mailer' folder:
    # part :content_type => "text/html", 
      # :body => email_header + render_message(template_s, attributes_h) + email_footer
      
    # Need to ensure the following template exists in the 'views/my_mailer' folder:
    part :content_type => "text/html", :body => render_message(template_s, attributes_h)
  end
  
  def email_header
    '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
       "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">

    <html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
      <head>
          <meta http-equiv="content-type" content="text/html;charset=UTF-8" />
      </head>
    <body>'
  end
  
  def email_footer
    '</body>
    </html>'
  end
end
