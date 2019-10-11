require 'digest'

class UserMessagesController < ApplicationController
  
  def view_inbox_messages
    session[:page] = "inbox"
    
    @data_attributes_h[:recipient_id] = session[:user].id.to_s
    @results_h = MyMailerMetadata::get_inbox_messages(@data_attributes_h)
    @messages = @results_h[:collection]
    
    render 'messages/view_messages.html', :layout => 'role_application'
  end
  
  def view_sent_messages
    session[:page] = "sent_messages"
    
    @data_attributes_h[:sender_id] = session[:user].id.to_s
    @results_h = MyMailerMetadata::get_sent_messages(@data_attributes_h)
    @messages = @results_h[:collection]
    
    render 'messages/view_messages.html', :layout => 'role_application'
  end
  
  def view_inbox_message
    session[:page] = "inbox"
    
    @data_attributes_h[:recipient_id] = session[:user].id.to_s
    @data_attributes_h[:message_id] = params[:message_id].to_i
    @results_h = MyMailerMetadata::get_inbox_message(@data_attributes_h)
    @messages = @results_h[:collection]
    
    @message_id = params[:message_id]
    
    # Update the notifications bar
    notifications
    
    render 'messages/view_message.html', :layout => 'role_application'
  end
  
  def view_sent_message
    session[:page] = "sent_messages"
    
    @data_attributes_h[:message_id] = params[:message_id].to_i
    @results_h = MyMailerMetadata::get_sent_message(@data_attributes_h)
    @messages = @results_h[:collection]
    
    @message_id = params[:message_id]
    
    render 'messages/view_message.html', :layout => 'role_application'
  end
  
  def reply_to_message
    session[:page] = "reply_message"
    
    @message = MyMailerMetadata::get_reply_message(session[:user].id.to_s, params[:message_id].to_i)
    @subject = @message.subject
    @subject = "RE: " + @subject if !@message.subject.start_with?("RE: ")

    render 'messages/reply_to_message.html', :layout => 'role_application'
  end
  
  def send_reply_to_message
    flash[:notice] = flash[:error] = nil
    
    respond_to do |format|
      
      #TODO:Add data fields check and ask to confirm after clicking 'cancel'
      if params[:cancel]
        
        format.html { redirect_to :action => :view_inbox_message, :controller => :user_messages }
          
      else
        
        begin
        
          @message_form = MessageForm.new(params[:message_form])
          
          @message_form.sender_name = session[:user].first_name + ' ' + session[:user].last_name
          @message_form.sender_email = session[:user].primary_email
          
          failed_validation = false
          failed_validation = true if !@message_form.valid?
          raise 'ERROR' if failed_validation
          
          @params_h = Hash.new
          @params_h[:parent_message_id] = params[:parent_message_id].to_s
          @params_h[:subject] = params[:message_subject].to_s
          @params_h[:message_body] = @message_form.body
          
          @params_h[:sender_id] = session[:user].id 
          @params_h[:sender_reply_to_email] = session[:user].primary_email
          @params_h[:sender_name] = session[:user].first_name + ' ' + session[:user].last_name
          
          # The following lines are suitable for 'user to user'
#          @recipient_user = Person.find(params[:message_recipient_id].to_s)

#          @params_h[:recipients] = Array.new(1, Hash.new)
#          @params_h[:recipients][0][:id] = @recipient_user.id
#          @params_h[:recipients][0][:email] = @recipient_user.primary_email
#          @params_h[:recipients][0][:name] = @recipient_user.first_name + ' ' + @recipient_user.last_name
          
          raise 'ERROR #2' if !send_message(@params_h, nil, true, params[:message_type_id].to_s.to_i, 1)          
          
          flash[:notice_hold] = 'Message was sent successfully!'
          format.html { redirect_to :action => :view_inbox_messages, :controller => :user_messages }
        
        rescue Exception => exc
            
          flash[:error] = 'Errors were found in the fields below, please check the messages next to each field'
          
          @message = MyMailerMetadata::get_reply_message(session[:user].id.to_s, params[:message_id].to_i)
          @subject = @message.subject
          @subject = "RE: " + @subject if !@message.subject.start_with?("RE: ") 
          
          format.html { render 'messages/reply_to_message.html', :layout => 'role_application' }
          
        end # rescue
        
      end # else      
    end # respond_to    
  end
    
end
