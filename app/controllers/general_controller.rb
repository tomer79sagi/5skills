# The 'main' controller will serve public pages that do not require authentication

class GeneralController < BaseController
  
  def iframe_test
    @flyc_action = params[:flyc_action]
    
    render 'general/iframe_test.html', :layout => false
  end
  
  def about_us
    
    render 'general/about_us.html', :layout => 'role_application'
    
  end
  
  def prep_contact_us_details
    @contact_us = MessageForm.new
    
    if session[:user]
      @contact_us.sender_name = session[:user].first_name + " " + session[:user].last_name
      @contact_us.sender_email = session[:user].primary_email
    else
      @contact_us.sender_name = nil
      @contact_us.sender_email = nil
    end
  end
  
  #
  # This action is a generic action that requires a 'return_to' attribute in the session
  #
  def contact_us
    
    @message_form = MessageForm.new
    
    if session[:user]
      @message_form.sender_name = session[:user].first_name + " " + session[:user].last_name
      @message_form.sender_email = session[:user].primary_email
    else
      @message_form.sender_name = nil
      @message_form.sender_email = nil
    end
    
    render 'general/contact_us.html', :layout => 'role_application'
    
  end
  
  def send_contact_us
    
    if params[:cancel]
      
      redirect_to(session[:last_primary_activity_o].to_link_to_options)
      
    else
      
      begin
        
        @params_h = Hash.new
        @message_form = MessageForm.new(params[:message_form])
        
        if session[:user]
          @message_form.sender_name = session[:user].first_name + ' ' + session[:user].last_name
          @message_form.sender_email = session[:user].primary_email
          
          @params_h[:sender_id] = session[:user].id
        else
          @params_h[:sender_id] = 0
        end
          
        failed_validation = false
        failed_validation = true if !@message_form.valid?
        raise 'ERROR' if failed_validation
        
        # @params_h[:parent_message_id] will auto-populate with the same id as the message being created (as this is a 'new' message)
        # @params_h[:subject] will auto-populate based on the message type (i.e. contact_us) 
        @params_h[:message_body] = @message_form.body
        @params_h[:sender_reply_to_email] = @message_form.sender_email
        @params_h[:sender_name] = @message_form.sender_name
        
        raise 'ERROR #2' if !send_message(@params_h, nil, false, 1, 1)          
        
        flash[:notice_hold] = 'Message was sent successfully!'
        
        if session[:user]
          redirect_to(session[:last_primary_activity_o].to_link_to_options)
          return
        end
        
        redirect_to({:action => :home, :controller => :application})
      
      rescue Exception => exc
            
        flash[:error] = 'Errors were found in the fields below, please check the messages next to each field'
        
        puts "!! Exception: " + exc.message
        
        render 'general/contact_us.html', :layout => 'role_application'
        
      end # rescue
        
    end
    
  end
    
end
