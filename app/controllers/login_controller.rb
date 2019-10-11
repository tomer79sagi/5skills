# The 'login' controller will serve public pages that do not require authentication

class LoginController < BaseController
  
  # Make sure the 'options' HTTP method is translated into the appropriate method
  # Using the CORS mechanism
  
  before_filter :login_required, :except => 
    [:home, 
    :process_login,
    :admin]
  
  def login_required
    
#    puts "YYYYYY: " + action_name
    
    # Once the user has logged in (first screen - bl_bookmark_site), do the following:
    # 1. Store a time-limited 'DB session' which will be checked once the session doesn't have the 'user' object
    # 2. Pass through a 'flag' in each 'json' request to request the BL to check the manual 'db' session
    # 3. Once the flag is identified, the system will check if the session hasn't expired, if it has, redirect the user to the login screen
    # 4. *** This should fix the 'post' with 'options' problem CORS type stuff 
    
    # Check if this is an 'admin' access attempt
    if request.env["PATH_INFO"].rindex("/admin") == 0
      
      return true if session[:user] && (session[:user].person_type_id == 0 && session[:user].primary_email == "admin@flyc.co.nz")
      
      # Otherwise, redirect to the 'admin' login page
      session[:return_to] = request.request_uri
      flash[:error] = 'Oops. You need to login before you can view that page.'
      flash[:action] = "login"
      
      redirect_to :controller => 'admin_login', :action => 'admin_home'
      return
      
    # If user logged in was 'Admin' and now a standard user is trying to access a non-admin page, logout admin and clear session
    elsif session[:user] && (session[:user].person_type_id == 0 && session[:user].primary_email == "admin@flyc.co.nz")
    
      @timer = session[:perf]
      reset_session
      session[:perf] = @timer
      
    end # Otherwise, it's probably a standard user that is trying to access a page
    
    ## Second, check if auto-login is selected
    login_from_cookie if session[:user].nil? 
    
    return true if session[:user]
    
    ## otherwise execute access denied message
    access_denied
  end
    
  def login_from_cookie
    flash[:notice] = 'Welcome back. We logged you in automatically as you chose Flyc to remember you.'
    
    return unless cookies[:auth_token] && session[:user].nil?
    
    @person = Person.find_by_remember_token(cookies[:auth_token])
    
    if @person && !@person.remember_token_expires.nil? && Time.now < @person.remember_token_expires
       session[:user] = @person
    end
  end    

  def access_denied
    flash.clear
    flash[:error] = 'Oops. You need to login before you can view that page.'

    session[:return_to] = request.request_uri
    redirect_to :controller => 'login', :action => 'home'
  end
    
  def process_login
    @response_message = 'Logged in successfully.'
    @is_success = true
    
    #
    # ERROR CODES:
    # -------------
    #
    #  100 - Fields not valid (in a form)
    #  101 - User can't be authenticated (either email or password incorrect)
    # 
    @error_code = 100 # Fields not valid
    
    @person_login = PersonLogin.new(params[:person_login])
    
    ## Check if login attributes are valid (before doing a full database check)
    if @person_login.valid?
      
      ## Authenticate and store user object in session
      if session[:user] = Person.authenticate(params[:person_login])
        
        ## Check if 'save_login' has been checked (for auto-login)        
        init_cookie_login_from_session if params[:save_login][:checked] == "yes"
        
        # Check if the user has confirmed registration
        if session[:user].status_id == 1 # Added to site (but not registered yet
          @response_message = "You have not yet registered to the site, please register first."
          @is_success = false
        
        end
        if session[:user].status_id == 2 # Registered but not confirmed
          @response_message = "You haven't confirmed your registration yet, please click the link in your email."
          @is_success = false
        end
        
        if session[:user].status_id == 3 # Registration confirmed 
          @response_message = 'Logged in successfully.'
        end
      else
        @error_code = 101
        @response_message = 'Either Email or Password are incorrect.'
        @is_success = false
      end
    else
      @response_message = "Errors found in fields!!"
      @is_success = false
    end
    
    if @is_success
      flash[:notice_hold] = @response_message
      
      return if params[:controller] == "bookmarklet"
      
      redirect_to session[:return_to] || {:action => 'view_applications', :controller => :role_applications}
      return
    else
      flash[:error] = @response_message
      
      return if params[:controller] == "bookmarklet"
      
      render '/main/homepage.html', :layout => "homepage"
    end
  end
  
  def init_cookie_login_from_session
    session[:user].remember_me
    cookies[:auth_token] = { :value => session[:user].remember_token , :expires => session[:user].remember_token_expires }
  end

  def logout
    # Capture the timer before resetting the session attribute
    @timer = session[:perf]
    @last_primary_activity = session[:last_primary_activity_o]

    # Remove the 'bookmarklet_session_token' (in case this action was initiated by the 'host site')
    session[:user].update_attribute(:bookmarklet_session_token, nil)
    
    reset_session
    
    # Assigning the timer to the session object again
    session[:perf] = @timer
    session[:last_primary_activity_o] = @last_primary_activity
    
    session[:user].forget_me if session[:user]
    session[:user] = nil
    cookies.delete :auth_token
    
    return if params[:controller] == "bookmarklet"

    flash[:notice] = 'Logged out successfully.'
    render '/main/homepage.html', :layout => "homepage"
    
  end
end
  