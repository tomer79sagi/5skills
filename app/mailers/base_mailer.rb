class BaseMailer < ActionMailer::Base
    
  def forward_email(params)
    @recipients = params[:recipients]
    @from = params[:from]
    @subject = params[:subject]
    @reply_to = params[:reply_to]
    @sent_on = Time.now
    
    part :content_type => "text/html", :body => render_message('forward_email.html', {:content => params[:content]})
  end
  
end
