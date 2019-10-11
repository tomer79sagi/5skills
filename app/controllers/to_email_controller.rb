require 'json'

class ToEmailController < ActionController::Base
  
  include ActionView::Helpers::DateHelper
  
  helper :all # include all helpers, all the time

  def sms_reciever
    
    text = ""
  
    if !request[:to] || !request[:msisdn] || !request[:text]
      
      text = "---- not inbound message ----"
      
    else
      
      text = "Inbound message - From: " + request[:msisdn] + "<br/>"
      text += "Inbound mssage - Body: " + request[:text]
    
    end
    
    text = "<html><body>" + text + "</body></html>"
    
    render :text => text
  
  end
  
    
end


