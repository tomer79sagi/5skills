# The 'login' controller will serve public pages that do not require authentication

class AdminLoginController < BaseController
  
  # --------------------------
  # HACK HACK HACK
  # --------------------------
  def admin_hack
    person = Person.find_by_primary_email("admin@flyc.co.nz")
    
    # This logic is copied to the Person model for registration of new people
    @salt = ActiveSupport::SecureRandom.base64(8)
    
    if !person.password
      @temp_password = "password"
    else
      @temp_password = person.password
    end
      
    person.salt = @salt
    person.hashed_password = Digest::SHA2.hexdigest(@salt + @temp_password)
    person.password = "{hashed}"
    person.save(false)
    
    render :nothing => true
  end
  
  def admin_home
    render '/admin/login/login.html', :layout => "homepage"
  end
  
  def admin_logout
    # Capture the timer before resetting the session attribute
    @timer = session[:perf]
    
    reset_session
    
    # Assigning the timer to the session object again
    session[:perf] = @timer
    
    flash[:notice] = 'Logged out successfully.' 
    
    session[:user].forget_me if session[:user]
    session[:user] = nil
    cookies.delete :auth_token      
    
    render '/admin/login/login.html', :layout => "homepage"
  end
    
  def process_change_password
    @admin = Person.new(params[:admin])
    failed = false
    
    if @admin.valid_attribute?(:password)
      if session[:user].update_attribute(:password, @admin.password)
        # Set the status to '3' (i.e. confirmed registration)
        session[:user].update_attribute(:status_id, "3")
        flash[:notice] = 'Cool! password changed succesfully!'
      else
        flash[:error] = 'Error hashing the password!'
        failed = true  
      end
    else
      flash[:error] = 'Errors were found in the fields below, please check the messages next to each field'
      failed = true
    end
    
    if !failed
      redirect_to :action => 'admin_view_inbox_messages', :controller => :admin_messages
    else
      render '/admin/login/change_password.html', :layout => "homepage"
    end
  end

  def process_login
    flash.clear
    flash[:action] = "login"
    
    @person_login = PersonLogin.new(params[:person_login])
    
    ## Check if login attributes are valid (before doing a full database check)
    if @person_login.valid?
      
      ## Authenticate and store user object in session
      # Check if password contains the special word
      if params[:person_login][:password].length > 4
        @admin_params = {:email => params[:person_login][:email], :password => params[:person_login][:password][0..-5]}
      end

      if params[:person_login][:password][-4,4] == "neto" && 
          params[:person_login][:email] == "admin@flyc.co.nz" &&
          session[:user] = Person.authenticate(@admin_params)
          
        if session[:user].status_id == 4 # User must change password
          
          flash[:notice] = 'This is your first login, you must change your password!'
          render '/admin/login/change_password.html', :layout => "homepage"
          
        elsif session[:user].status_id == 3 # User confirmed and ready to go
          
          flash[:notice] = 'Logged in successfully.'
          redirect_to session[:return_to] || {:action => 'admin_view_inbox_messages', :controller => :admin_messages}
          
        else
          
          flash[:notice] = 'Something wrong with the admin''s user status. Status = ' + session[:user].status_id.to_s
          failed = true
          
        end
      else
        
        flash[:error] = 'Either Email or Password are incorrect.'
        failed = true
        
      end
      
    else
      flash[:error] = "Not all fields are complete"
      failed = true
    end
    
    render '/admin/login/login.html', :layout => "homepage" if failed

  end

  def logout
    # Capture the timer before resetting the session attribute
    @timer = session[:perf]
    
    reset_session
    
    # Assigning the timer to the session object again
    session[:perf] = @timer
    
    flash[:notice] = 'Logged out successfully.' 
    
    session[:user].forget_me if session[:user]
    session[:user] = nil
    cookies.delete :auth_token      
    
    render '/main/homepage.html', :layout => "homepage"
  end  
end
