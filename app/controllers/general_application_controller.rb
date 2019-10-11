require 'mechanize'

class GeneralApplicationController < ApplicationController
  
  def mechanize
    
    agent = Mechanize.new
    page = agent.get('http://google.com/')
    
#    pp page

    a = Mechanize.new { |agent|
      agent.user_agent_alias = 'Mac Safari'
    }
    
    a.get('http://google.com/') do |page|
      search_result = page.form_with(:name => 'f') do |search|
        search.q = 'Hello world'
      end.submit
      
      puts search_result.body
    
      search_result.links.each do |link|
    #    puts link.text
      end
      
#      render :text => search_result.body, :layout => false, :content_type => 'text/html'
      redirect_to search_result.uri.to_s
    end

#      @body = page.body
#      
#      puts "XXXXXX: " + page.uri.to_s

#      render 'general_application/mechanize.html', :layout => false
    
  end
  
  def activities
    
    @activities = Activity.find_all_by_person_id(session[:user].id, :order => "created_at desc")
    
    render 'general_application/activities.html', :layout => 'role_application'
    
  end
  
  def provide_feedback
    
    @message_form = MessageForm.new
    
    @message_form.sender_name = session[:user].first_name + " " + session[:user].last_name
    @message_form.sender_email = session[:user].primary_email
    
    @feedback_for_page = "Unknown"
    @feedback_for_page = Activity::activities[session[:last_primary_activity_o][:action]][0] if
      Activity::activities[session[:last_primary_activity_o][:action]]
    
    render 'general_application/provide_feedback.html', :layout => 'role_application'
    
  end
  
  def send_feedback
    
    if params[:cancel]
      
      redirect_to(session[:last_primary_activity_o].to_link_to_options)
      
    else
      
      begin
        
        @params_h = Hash.new
        @message_form = MessageForm.new(params[:message_form])
        
        @message_form.sender_name = session[:user].first_name + ' ' + session[:user].last_name
        @message_form.sender_email = session[:user].primary_email
        
        @params_h[:sender_id] = session[:user].id
          
        failed_validation = false
        failed_validation = true if !@message_form.valid?
        raise 'ERROR' if failed_validation
        
        # @params_h[:parent_message_id] will auto-populate with the same id as the message being created (as this is a 'new' message)
        # @params_h[:subject] will auto-populate based on the message type (i.e. contact_us) 
        @params_h[:message_body] =
           '<p>' + 
           '<b>Feedback for <u>"' + params[:page_for_feedback].to_s + '"</u></b>' + 
           '</p>' + 
           @message_form.body 
            
        @params_h[:sender_reply_to_email] = @message_form.sender_email
        @params_h[:sender_name] = @message_form.sender_name
        
        @my_mailer_metadata = send_message(@params_h, nil, false, 7, 1)
        raise 'ERROR #2 - sending message' if !@my_mailer_metadata
        
        @feedback = Feedback.new
        @feedback.action = session[:last_primary_activity_o][:action].to_s 
        @feedback.controller = session[:last_primary_activity_o][:controller].to_s
        @feedback.my_mailer_metadata_id = @my_mailer_metadata.id
        
        failed_save = false
        failed_save = true if !@feedback.save 
        raise 'ERROR #3 - storing feedback object' if failed_save
        
        flash[:notice_hold] = 'Feedback was sent successfully!'
        
        redirect_to(session[:last_primary_activity_o].to_link_to_options)
      
      rescue Exception => exc
            
        flash[:error] = 'Errors were found in the fields below, please check the messages next to each field'
        
        puts "!! Exception: " + exc.message
        
        @feedback_for_page = "Unknown"
        @feedback_for_page = Activity::activities[session[:last_primary_activity_o][:action]][0] if
          Activity::activities[session[:last_primary_activity_o][:action]]
        
        render 'general_application/provide_feedback.html', :layout => 'role_application'
        
      end # rescue
        
    end
    
  end
    
end
