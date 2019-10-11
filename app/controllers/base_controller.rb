require 'tzinfo'

class BaseController < ActionController::Base
  helper :all # include all helpers, all the time
  protect_from_forgery # See ActionController::RequestForgeryProtection for details

#  before_filter :print_headers
  
  before_filter :cors_preflight_check
  after_filter :cors_set_access_control_headers
  
  before_filter :performance, :activity_logger_start, :initialize_timezone
#  after_filter :activity_logger_end
  after_filter :clear_soft_messages
  
  def print_headers
    for header in request.env.select {|k,v| k.match("^HTTP.*")}
      puts "XXX: " + header[0] + " ; " + header[1]
    end
  end
  
  # For all responses in this controller, return the CORS access control headers.
  def cors_set_access_control_headers
    headers['Access-Control-Allow-Origin'] = '*'
    headers['Access-Control-Allow-Methods'] = 'POST, GET, OPTIONS'
    headers['Access-Control-Max-Age'] = "1728000"
  end
  #
  ## If this is a preflight OPTIONS request, then short-circuit the
  ## request, return only the necessary headers and return an empty
  ## text/plain.
  #
  def cors_preflight_check
    if request.method == :options
      headers['Access-Control-Allow-Origin'] = '*'
      headers['Access-Control-Allow-Methods'] = 'POST, GET, OPTIONS'
      headers['Access-Control-Allow-Headers'] = 'X-Requested-With, X-Prototype-Version, Content-Length, bookmarklet_session_token, Content-Type'
      headers['Access-Control-Max-Age'] = '1728000'
      render :json => {}, :content_type => "application/json"
    end
  end
  
  def performance
    session[:perf] = Time.now
  end
  
  # Identify the timezone based on the IP of the remote computer
  def initialize_timezone 
    if !session[:user_country]
      
#      my_ip = request.remote_ip
      my_ip = "93.172.139.218"
      my_ip_a = my_ip.split(".")
      
      my_ip_as_number = my_ip_a[3].to_i + 
        (my_ip_a[2].to_i * 256) + 
        (my_ip_a[1].to_i * 256 * 256) +
        (my_ip_a[0].to_i * 256 * 256 * 256)
      
      @ip_to_country = IpToCountry.find_by_sql("SELECT " + 
          "ctry, cntry, country " +
        "FROM " + 
          "ip_to_countries " + 
        "WHERE " + 
          my_ip_as_number.to_s + " >= ip_from " +
          "and " + my_ip_as_number.to_s + " <= ip_to")
          
      if @ip_to_country
        @ip_to_country = @ip_to_country[0]
        session[:user_country] = @ip_to_country
      end 
          
    end
 
  end
  
  #
  # This method will record all activity on the site
  #
  # The @friendly_names_h Hash is created here and is expected to be populated with the DB value matching a particular ID
  # Each controller will need to populate this Hash for the activity_logger to record the activity information correctly in the database
  # Example: "@friendly_names_h["organisation_id"] = @organisation_summary.organisation_name"
  #   (see 'application_controller:populate_organisation_summary' for a better explaination of this
  # 
  def activity_logger_start
    @friendly_names_h = Hash.new 
    
    #puts "Test: " + Dir.entries(".").join(",")
  end
  
  # This method will clear all 'notice' and 'error' messages after the 'render' is executed!
  #
  def clear_soft_messages
    if flash[:notice_hold]
      flash[:notice] = flash[:notice_hold]
      flash[:notice_hold] = nil
    elsif !flash[:notice_hold]
      flash[:notice] = nil  
    end
    
    if flash[:error_hold]
      flash[:error] = flash[:error_hold]
      flash[:error_hold] = nil
    elsif !flash[:error_hold]
      flash[:error] = nil  
    end
    
    if flash[:action_hold]
      flash[:action] = flash[:action_hold]
      flash[:action_hold] = nil
    elsif !flash[:action_hold]
      flash[:action] = nil  
    end
  end
  
  # Syntax samples:
  #
  # 1. "'User' 'viewed' 'notes' for 'application' 'Project Manager'
  # 2. "'User' 'edited' 'note' 'Blah blah...' for 'application' 'Project Manager'
  # 3. "'Updated' 'note' 'Blah Blah...' for 'application' 'Project Manager'" -> Successfully updated the note
  # 4. "'Created' 'note' 'ASD ASD' for 'application' 'Project Manager'" -> Successfully created and saved a new note
  # 5. "'Assigned' 'agency' '920' for 'application' 'Project Manager'"
  # 6. "'Updated' 'application' 'Project Manager', 'assigned' 'agency' '920'
  # 7. "'Removed' 'agency' '920' from 'application' 'Project Manager'"
  #
  # 5 or 6 elements:
  #  - User, e.g. 'John'  
  #  - Action, e.g. Created, Updated, Assigned
  #  - Major entity, e.g. Note
  #  - Major entity name, e.g. 'Blah blah'
  #  - Minor entity, e.g. application
  #  - Minor entity name, e.g. 'Project Manager'
  # 
  # In between, connection words will be used, e.g.
  #  - 'of', e.g. 'Viewed notes of application', 'Updated note of application'
  #  - 'for', e.g. 'Created note for application'
  #  - 'to', e.g. 'Assigned agency to application'
  #  - 'from', e.g. 'Removed agency from application'
  #
  def activity_logger_end
    # Don't care about logging activity if the user is not registered
#    return if !session[:user]

    puts "In: Logger End"

    # In case the request is of type '2' = AJAX (dynamic), store 'session' information for content storage between
    # AJAX pages but don't record a database activity (making the transition faster)
    if Activity::activities[params[:action]] && Activity::activities[params[:action]][3] == 2
      
      # Store the AJAX data in the 'session' object under the general key ':params' with the 'page' being the 2nd 'key'
#      session[:params][params[:action]] = params
    end
    
    # If the current action & controller match the previous activity (i.e. the user has refreshed and clicked on a link
    # that takes them to the same page, the previous Activity will be updated with the 'updated_at' field ONLY
    if (session[:last_activity_o]) && 
        (session[:last_activity_o].action == params[:action] && session[:last_activity_o].controller == params[:controller])
      session[:last_activity_o].touch
      return
    end
    
    # If current activity is of type 'secondary'
    
    # 1. Maintain 5 last links in the session object
    session[:last_5_urls] = Array.new(5) if !session[:last_5_urls]
    session[:last_5_urls].unshift(request.env["REQUEST_URI"])
    session[:last_5_urls].pop if session[:last_5_urls].length > 5
    
    @activity = Activity::create_o(params, @friendly_names_h, session[:user])
              
    begin
      
#      @activity.save(false)
      
      # If current activity is of type 'primary', store it as primary
      # This will be used as a 'return_to' link when exiting a 'secondary' view
      if Activity::activities[params[:action]] && Activity::activities[params[:action]][3] == 1
        session[:last_primary_activity_o] = @activity
        
      # 2. In case current page is secondary (e.g Feedback, Contact Us etc) and there is no 'last_primary_activity' object in memory
      # E.g. user bookmarked the 'Provide Feedback' page and 2nd time opening the browser, using cookie login, they access this page directly
      elsif !session[:last_primary_activity_o] &&
        (Activity::activities[params[:action]] && Activity::activities[params[:action]][3] == 0)
      
      # 3. If the current action is not defined regardless if it's a primary or secondary (as we can't tell at this stage)
      #    Set the 'last_primary_activity' to 'home'
      elsif !Activity::activities[params[:action]] 
        session[:last_primary_activity_o] = Activity::create_o(
          {:action => "home", :controller => "application"}, nil, session[:user])
          
        # Let the admin know an action was used that doesn't have
        raise 'ERROR #2' if !send_message(nil, {:missing_action => params[:action]}, false, 3, 4)  
      end 
      
      # Set the current activity to be the last in the session
      session[:last_activity_o] = @activity
      
    rescue Exception => exc
      
      flash[:error] = 'Activity could not be saved due to a validation error = ' + exc.clean_backtrace.join( "\n" )
      
    end # rescue
      
  end
  
  def send_message(metadata_params_h, body_params_h, is_reply, type = 0, exchange_type = 0)
    body_params_h = Hash.new if !body_params_h
    body_params_h["http_host"] = request.env["HTTP_HOST"]
    
#    return MyMailer::send_message(metadata_params_h, body_params_h, is_reply, type, exchange_type)
    return MyMailer::send_message_delayed(metadata_params_h, body_params_h, is_reply, type, exchange_type)
  end
    
end
