# The 'login' controller will serve public pages that do not require authentication
# require 'linkedin'

require 'oauth'
require 'cloudinary'

class FsLoginController < FiveSkillsController
  
  
  ## Exception Handling
  class APIAuthError < StandardError; end
  
  
  LINKEDIN_API_KEY = 'qyskfuh30ovp'
  LINKEDIN_API_SECRET = 'FyB8irPnXoxZNEvl'
  
  LINKEDIN_CALLS = [
    "my_profile",  # 0
    "my_profile__no_connections",  # 1
    nil,
    nil,
    "my_profile__with_connections",  # 4
    nil,
    nil,
    nil,
    nil,
    nil,
    nil,
    "my_groups",  # 11
    "post_to_single_group",  # 12
    "my_job__publishing_groups",  # 13
    "publish_my_job"  # 14
    ]
  
  
  # Make sure the 'options' HTTP method is translated into the appropriate method
  # Using the CORS mechanism
  
  
  before_filter :a_recruiter__login_required,
    :except => [
      :a_recruiter__do_linkedin_login,
      :a_recruiter_restart,
      :a_recruiter__view_job_post,
      :ajax_a_recruiter_publish_job,
      
      :linkedin_auth_accept, 
      :linkedin_auth_cancel,
      
      
      # --- Job seeker ---
      
      :ajax_apply_to_job_post,
      :ajax_save_job_seeker_fs_profile,
      :ajax_i_want_more_jobs,
      :fajax_send_job_post_application
            
    ]
  
  
  before_filter :login_required, 
    :except => [
      
      
      # --- A RECRUITER - 1st TEST ---
      # Disable this filter for this new version (Mar 2014)
      
      :a_recruiter_home,
      :a_recruiter_publish_job,
      :a_recruiter_job_publishing_home,
      :a_recruiter__do_linkedin_login,
      :a_recruiter_restart,
      :fajax__publish_job,
      :ajax_get_linkedin_groups,
      :ajax_a_recruiter_publish_job,
      :a_recruiter__view_job_post,
      
      
      # --- Job seeker ---
      
      :view_job_post,
      :seeker_home,
      
      :ajax_apply_to_job_post,
      :ajax_save_job_seeker_fs_profile,
      :ajax_i_want_more_jobs,
      :fajax_send_job_post_application,
      
      
      # --- Recruiter ---
      
      :recruiter_home,
      :ajax_search_job_seekers, 
      :ajax_save_job_fs_profile,
      :ajax_get_social_groups,
      :ajax_post_job_to_social_group,
      
      # --- Alpha features ---
      :ajax_get_job_publishing_info,
      :ajax_publish_job,
      
      
      # --- Version 1 ---
      
      :view_seeker_profile,
      
      
      :linkedin_catchup, :linkedin_catchup_connections, :scraper_catchup,
      :view_seeker_profile_by_recruiter, 
      :seek_job_seekers,
      :search_job_seekers,
      :remove_entity,
      
      :public_profile, :home, :do_login, 
      :do_linkedin_login, :linkedin_auth_accept, :linkedin_auth_cancel,
      :do_register, :do_logout,
      :show_file, :view_company_summary, :view_agency_summary,
      :create_job_seeker_profile]
      
  before_filter :check_permissions,
    :except => [
      
      # --- A RECRUITER - 1st TEST ---
      # Disable this filter for this new version (Mar 2014)
      
      :a_recruiter_home,
      :a_recruiter_publish_job,
      :a_recruiter_job_publishing_home,
      :a_recruiter__do_linkedin_login,
      :a_recruiter_restart,
      :fajax__publish_job,
      
      :ajax_a_recruiter_publish_job,
      :a_recruiter__view_job_post,
      
      :ajax_get_linkedin_groups,
      :ajax_get_job_status,
      
      
      # --- Job seeker ---
      
      :view_job_post,
      :seeker_home,
      
      :ajax_apply_to_job_post,
      :ajax_save_job_seeker_fs_profile,
      :ajax_i_want_more_jobs,
      :fajax_send_job_post_application,
      
      
      # --- Recruiter ---
      
      :recruiter_home,
      :ajax_search_job_seekers, 
      :ajax_save_job_fs_profile,
      :ajax_get_social_groups,
      :ajax_post_job_to_social_group,
      
      # --- Alpha features ---
      :ajax_get_job_publishing_info,
      :ajax_publish_job,
      
      
      # --- Version 1 ---
      
      :view_seeker_profile,
      
      
      :linkedin_catchup, :linkedin_catchup_connections, :scraper_catchup,
      :view_seeker_profile_by_recruiter,
      :seek_job_seekers,
      :search_job_seekers,
      :remove_entity,
      
      :public_profile, :home, :do_login, 
      :do_linkedin_login, :linkedin_auth_accept, :linkedin_auth_cancel,
      :do_register, :do_logout,
      :show_file, :view_company_summary, :view_agency_summary,
      :create_job_seeker_profile]
  
  ACTIONS_USER_PERMISSIONS = {
    
    :job_seeker => [
      "find_jobs", "search_jobs",
      
      "save_job_seeker_fs_profile_ajax",
      
      "create_job_seeker_profile", "save_job_seeker_profile", 
      "view_job_seeker_profile", "edit_job_seeker_profile", "update_job_seeker_profile",
      "send_cv_to_job", "cv_request_approve", "cv_request_reject",
      "view_job_matches", "manage_job_seeker_settings", "update_job_seeker_settings",
      
      "view_job_profile", "jobs_cv_delivery_log", "apply_for_job", "send_job_application", 
      
      "view_template", "create_template", "download_file"],
      
    :contact => [
      "find_job_seekers", "search_job_seekers",
      
      "save_job_fs_profile_ajax",
      
      "create_job_profile", "save_job_profile", 
      "view_job_profile", "edit_job_profile", "update_job_profile",
      "request_cv_from_job_seeker",
      "view_job_seeker_matches", "manage_job_settings", "update_job_settings",
      
      "view_job_seeker_profile", "job_seekers_cv_delivery_log",
      
      "view_template", "create_template", "download_file"]}
    
  def check_permissions
    return true if session[:admin]
    
    if session[:user]
      
      if ((session[:user].user_type_id == Fs2User::USER_TYPES[:job_seeker] && ACTIONS_USER_PERMISSIONS[:job_seeker].index(params[:action]).nil?) || 
          ((session[:user].user_type_id == Fs2User::USER_TYPES[:recruitment_agent] || session[:user].user_type_id == Fs2User::USER_TYPES[:hiring_manager]) && 
          ACTIONS_USER_PERMISSIONS[:contact].index(params[:action]).nil?)) || 
        
        # Ensure 'job seekers' can only update their own profiles
        (["edit_job_seeker_profile", "update_job_seeker_profile"].index(params[:action]) && session[:person].id != params[:job_seeker_id].to_i) || 
        
        # Ensure 'contacts' can only update their own jobs
        (["edit_job_profile", "update_job_profile"].index(params[:action]) && session[:jobs].has_key?([params[:job_id]]))
            
          flash[:error_hold] = 'Oops. You are not allowed to see this page with your account type.<br/>Log out and login with the correct account type.'
          redirect_to :action => :home, :controller => :five_skills
          return false
        
      end
      
    end
  end
  
  def remove_entity
    if params[:tomer] && params[:tomer] == "sagi"
      
      Fs2User.delete(session[:user].id) if session[:user]
      Fs2JobSeeker.connection.execute("delete from fs2_job_seekers where user_id = " + session[:user].id.to_s) if session[:user]
      Fs2UserConnector.connection.execute("delete from fs2_user_connectors where user_id = " + session[:user].id.to_s) if session[:user]
      Fs2CvEducation.connection.execute("delete from fs2_cv_educations where cv_id = " + cv.id)
      
      cv = Fs2Cv.find_by_job_seeker_id(session[:job_seeker_id].id.to_s) if session[:job_seeker_id]
      if cv
        Fs2Cv.connection.execute("delete from fs2_cvs where id = " + cv.id)
        Fs2CvPosition.connection.execute("delete from fs2_cv_positions where cv_id = " + cv.id)
        Fs2CvEducation.connection.execute("delete from fs2_cv_educations where cv_id = " + cv.id)
      end
      
      fs_profile = Fs2SkillsProfile.find_by_entity_id(session[:user].id) if session[:user]
      delete_fs_profile_by_fs_profile_id(fs_profile.id) if fs_profile
      
      reset_session
      cookies.delete :user_id
      redirect_to :home 
      
    end
  end
  
  def a_recruiter__login_required
   
    ## Auto-login is a default
    # login_from_cookie if session[:user].nil? 

    if session[:user] || params[:action] == 'a_recruiter_home'
      return true
    end
    
    ## otherwise execute access denied message
    a_recruiter__access_denied   
     
  end
  
  def a_recruiter__access_denied
    flash.clear
    flash[:error_hold] = 'Oops. You need to sign-up or login before you can view that page.'

    @user_type_id = Fs2User::USER_TYPES[:recruitment_agent]
    session[:return_to] = request.request_uri
    
    # render '/five_skills/home_logged_out.html', :layout => 'five_skills_homepage'
    redirect_to :action => :a_recruiter_home, :controller => :fs_job 
  end
  
  def login_required
    
    # session[:admin] = nil
    return true if session[:admin]
   
    ## Second, check if auto-login is selected
    # login_from_cookie if session[:user].nil? 

    return true if session[:user]
    
    ## otherwise execute access denied message
    access_denied
  end
    
  def login_from_cookie
    flash[:notice] = 'Welcome back. We logged you in automatically as you chose Flyc to remember you.'
    
    return unless cookies[:auth_token] && session[:user].nil?
    
    @user = Fs2User.find_by_remember_token(cookies[:auth_token])
    
    if @user && !@user.remember_token_expires.nil? && Time.now < @user.remember_token_expires
       session[:user] = @user
       init_person_objects
    end
  end    

  def access_denied
    flash.clear
    flash[:error_hold] = 'Oops. You need to sign-up or login before you can view that page.'

    @user_type_id = Fs2User::USER_TYPES[:job_seeker]
    session[:return_to] = request.request_uri
    
    # add_field_binder("search_company-name", "search_company-id", 
      # "view_company_summary", FIELD_COLLECTION_TYPES[:companies],
      # {:include_image => true})
    # add_field_binder("search_agency-name", "search_agency-id", 
      # "view_agency_summary", FIELD_COLLECTION_TYPES[:agencies],
      # {:include_image => true})
    
    # render '/five_skills/home_logged_out.html', :layout => 'five_skills_homepage'
    redirect_to :action => :home, :controller => :five_skills 
  end
  
  def do_register_in_process
    
    # -- Validation
    
    @user = Fs2User.new({
      :email => get_param([:user, :email]),
      :password => get_param([:user, :password]),
      :status_id => Fs2User::USER_STATUSES[:hit_apply_pre_registration]})
    if !@user.valid?
      flash[:error] = 'Login errors occured'
      return false
    end
    
    
    # --- Otherwise, register
    
    Fs2User.transaction do
          
      begin    
        
        session[:user].update_attributes({
          :email => get_param([:user, :email]),
          :password => get_param([:user, :password]),
          :status_id => Fs2User::USER_STATUSES[:registered]
        })
        
        # login_from_hash({:email => @user.email, :password => get_param([:user, :password])}, false)
      
      rescue Exception => exc
        
        ## Revert the 'hashed' password to 'normal string' password for continuity-sake
        flash[:error] = 'Login errors occured'
        return false
        
      end # rescue
    end # transaction
    
    return true
    
  end   
  
  def do_register
    flash.clear
    flash[:action] = "register"
    failed_validation = false
    
    #
    # 1. VALIDATION
    #
    @user = Fs2User.new({
      :email => get_param([:user, :email]),
      :password => get_param([:user, :password]),
      :status_id => Fs2User::USER_STATUSES[:registered]})
    
    failed_validation = true if !@user.valid?
      
    # In case the user is a 'Recruitment agent' or a 'Hiring manager'
    @user_type_id = get_param([:user_type, :type_id])
    
    if !@user_type_id.blank?
      @user_type_id = @user_type_id.to_i
      @user.user_type_id = @user_type_id
      
      if @user_type_id == Fs2User::USER_TYPES[:recruitment_agent] || @user_type_id == Fs2User::USER_TYPES[:hiring_manager]
        
        org_name = get_param(["search_agency-name"]) if @user_type_id == Fs2User::USER_TYPES[:recruitment_agent]
        org_name = get_param(["search_company-name"]) if @user_type_id == Fs2User::USER_TYPES[:hiring_manager]
        is_new_org = false
        
        org_type_id = Fs2Organisation::ORGANISATION_TYPES[:agency] if @user_type_id == Fs2User::USER_TYPES[:recruitment_agent]
        org_type_id = Fs2Organisation::ORGANISATION_TYPES[:company] if @user_type_id == Fs2User::USER_TYPES[:hiring_manager]
        
        @organisation = Fs2Organisation.find(:first, 
          :conditions => [ "lower(name) = ? AND organisation_type = ?", 
          org_name.downcase, org_type_id])
          
        if @organisation.nil?
          is_new_org = true
          @organisation = Fs2Organisation.new(params[:organisation])
          @organisation.name = org_name
          @organisation.organisation_type = Fs2Organisation::ORGANISATION_TYPES[:agency] if @user_type_id == Fs2User::USER_TYPES[:recruitment_agent]
          @organisation.organisation_type = Fs2Organisation::ORGANISATION_TYPES[:company] if @user_type_id == Fs2User::USER_TYPES[:hiring_manager]
          
          failed_validation = true if !@organisation.valid?
        end
              
        @person = Fs2Contact.new({
          :full_name => get_param([:person, :full_name]),
          :organisation_role => get_param([:contact, :organisation_role])})
          
        @person.contact_type = Fs2Contact::CONTACT_TYPES[:agency] if @user_type_id == Fs2User::USER_TYPES[:recruitment_agent]
        @person.contact_type = Fs2Contact::CONTACT_TYPES[:company] if @user_type_id == Fs2User::USER_TYPES[:hiring_manager]
        
        #TODO: Refactor ':contact' attribute to be completely separate for 'contact' objects and not partial with 'person' and 'contact'
        @contact = Fs2Contact.new({:organisation_role => @person.organisation_role})
              
      elsif @user_type_id == Fs2User::USER_TYPES[:job_seeker]
            
       @person = Fs2JobSeeker.new({
          :full_name => get_param([:person, :full_name])})
            
      end
      
      failed_validation = true if !@person.valid?
      
      #
      # 2. SAVING
      #
      Fs2User.transaction do
          
        begin    
          
          if !failed_validation
            
            @user.save(false)
            
            if @user_type_id == Fs2User::USER_TYPES[:recruitment_agent] || @user_type_id == Fs2User::USER_TYPES[:hiring_manager]
            
              @organisation.save(false) if is_new_org
              @person.organisation_id = @organisation.id
              
            end
              
            @person.user_id = @user.id
            @person.save(false)
            
          else
            
            err_msg = ""
            err_msg += @user.errors.full_messages.join(", ") if @user.errors
            err_msg += " | " + @organisation.errors.full_messages.join(", ") if @organisation && @organisation.errors
            
            raise 'ERROR!! ' + err_msg
            
          end
          
          respond_to do |format|
             
            login_from_hash({:email => @user.email, :password => get_param([:user, :password])}, false)
            return
            
          end
        
        rescue Exception => exc
          
          ## Revert the 'hashed' password to 'normal string' password for continuity-sake
          @user.password = get_param([:user, :password])
          flash[:error] = 'Errors were found in the fields below, please check the messages next to each field'
          
          respond_to do |format|
            format.html { render '/five_skills/home_logged_out.html', :layout => "five_skills_homepage" }
          end
          
        end # rescue
      end # transaction
    end
    
  end 
  
  def do_login
    flash[:action] = "login"
    
    h_params = {
      :email => params[:user_login][:email], 
      :password => params[:user_login][:password]}
      
    h_params[:save_login] = params[:save_login][:checked] if 
      params[:save_login] && params[:save_login][:checked] == "yes"
    
    login_from_hash(h_params)
  end
  
  
  def sync_user_publishing_channels(user_id, user_groups, required_channels = nil)
    
    # -- Try and find the relevant groups / channels
    stored_groups = Fs2MapUserToPublishingChannel.find(
      :all,
      :joins => ["LEFT JOIN `fs2_publishing_channels` ON fs2_publishing_channels.id = fs2_map_user_to_publishing_channels.publishing_channel_id"],
      :select => "fs2_map_user_to_publishing_channels.*, fs2_publishing_channels.channel_id", 
      :conditions => ["fs2_map_user_to_publishing_channels.user_id = ? AND fs2_publishing_channels.channel_id IN (?)", user_id.to_s, user_groups.collect { |e| e[0] }])
    
    
    # -- UPDATE
    
    if stored_groups && !stored_groups.empty?
      
      data_arr = []
      stored_groups.each do |found_user_channel|
        
        # Find a Channel in the 'user_groups' array -> by the 'group_id' (user was matched by the 'select' query above)
        new_user_channel = user_groups.assoc(found_user_channel.channel_id.to_s)
        
        # If an update exists (a potential STATUS update exists in the 'user_groups' array)
        if new_user_channel
          
          # add it to the UPDATE list pair -> [0] - user_channel_id, [1] - new 'status'
          data_arr << [ found_user_channel.id, new_user_channel[1] ]
          
          # Delete it from the 'user_groups' array -> so it can't be INSERTED in the next step
          user_groups.delete(new_user_channel)
          
        end
        
      end
      
      _sql_update = _construct_multiple_update_sql('fs2_map_user_to_publishing_channels', [ 'id', 'channel_status' ], data_arr )
      Fs2MapUserToPublishingChannel.connection.execute(_sql_update)
      
    end
    
    
    # -- CREATE
    
    if user_groups && !user_groups.empty?  # in case there are remaining elements to create
      data_arr = []
      
      if required_channels
        data[:required_channels].each { |ch_id, ch_obj| data_arr << [ user_id, ch_obj.id, user_groups.assoc(ch_obj.channel_id.to_s)[1] ] }
      else
        user_groups.each { |pair| data_arr << [ user_id, pair[0], pair[1] ] }
      end
      
      _sql_insert = _construct_multiple_insert_sql( 'fs2_map_user_to_publishing_channels', ['user_id', 'publishing_channel_id', 'channel_status'], data_arr)
      Fs2MapUserToPublishingChannel.connection.execute(_sql_insert)
    end    
  end  
  
  
  #
  # This method creates the 5skills user session information
  #
  def init_linkedin_session(access_token, access_secret)
    puts "---- init_linkedin_session"
    
    # Check if the user is registered in the system
    # 1. Get the basic user information from LinkedIn to perform checks on
    @my_profile = a_recruiter__do_linkedin(0)
    # @my_profile = do_linkedin(0)
    
    
    # -- [No active LinkedIn connection]
    if @my_profile.nil?
      
      session[:request_token] = get_linkedin_consumer().get_request_token({:oauth_callback => callback_url})
    
      if session[:request_token]
        session[:access_token] = session[:request_token].token
        session[:access_secret] = session[:request_token].secret
      end
      
      # -- Return the 'auth_url' if the method's 'get_aurh_url' flag is set to 'true'
      
      return session[:request_token].authorize_url
      
    end
      
      
    if @my_profile[:response_object]['id']
      user_connector = Fs2UserConnector.find_by_linkedin_id(@my_profile[:response_object]['id'])
    elsif @my_profile[:response_object]['emailAddress']
      user_connector = Fs2UserConnector.find_by_linkedin_email(@my_profile[:response_object]['emailAddress'])
    elsif @my_profile[:response_object]['publicProfileUrl']
      user_connector = Fs2UserConnector.find_by_linkedin_email(@my_profile[:response_object]['publicProfileUrl'])
    end
    
    # Update the access keys in case the 'user_connector' was found (a new one, an 'updated' one etc.)
    if user_connector
      user_connector.update_attributes({
          :linkedin_access_token => access_token,
          :linkedin_access_secret => access_secret
        })
    end
    
    if session[:user].nil?
      
      if user_connector && user_connector.user_id # exists in DB
        
        session[:user] = Fs2User.find_by_id(user_connector.user_id)
        
      else
        
        # Create USER
        session[:user] = Fs2User.new({
          :status_id => Fs2User::USER_STATUSES[:linkedin_signed_in], 
          :user_type_id => Fs2User::USER_TYPES[:job_seeker],
          :referral_id => session[:user_referral]
        })
        session[:user].email = @my_profile[:response_object]['emailAddress'] if @my_profile[:response_object]['emailAddress']
        session[:user].save(false)
        
        # Create JOB SEEKER
        full_name = ""
        full_name += @my_profile[:response_object]['firstName'] if @my_profile[:response_object]['firstName']
        if @my_profile[:response_object]['lastName']
          full_name += " " if !full_name.blank?
          full_name += @my_profile[:response_object]['lastName']  
        end
        
        # -- Save the contact details
        @person = Fs2Contact.new({:full_name => full_name})
        @person.user_id = session[:user].id
        @person.save(false)
        
        # -- No Company
        
        # Create USER CONNECTOR
        user_connector = Fs2UserConnector.new({
          :linkedin_access_token => session[:access_token],
          :linkedin_access_secret => session[:access_secret],
          :status_id => 1
          })
        user_connector.user_id = session[:user].id if session[:user]
        user_connector.linkedin_id = @my_profile[:response_object]['id'] if @my_profile[:response_object]['id']
        user_connector.linkedin_email = @my_profile[:response_object]['emailAddress'] if @my_profile[:response_object]['emailAddress']
        user_connector.linkedin_first_name = @my_profile[:response_object]['firstName'] if @my_profile[:response_object]['firstName']
        user_connector.linkedin_last_name = @my_profile[:response_object]['lastName'] if @my_profile[:response_object]['lastName']
        user_connector.linkedin_public_profile_url = @my_profile[:response_object]['publicProfileUrl'] if @my_profile[:response_object]['publicProfileUrl']
        user_connector.save(false)
        
      end
      
    end
    
    session[:user_connector_id] = user_connector.id
  
    job_seeker = Fs2JobSeeker.find_by_user_id(user_connector.user_id)
    session[:job_seeker_id] = job_seeker.id if job_seeker
    
    skills_profile = Fs2SkillsProfile.find(:first, :conditions => 
      ["profile_type = ? AND entity_type = ? AND entity_id = ?", 
      FS_PROFILE_TYPES[:user_profile], ENTITY_TYPES[:job_seeker], session[:job_seeker_id]]) if session[:job_seeker_id]
    session[:skills_profile_id] = skills_profile.id if skills_profile
    
    @my_profile[:response_object]
    
  end  
  
  
  #
  # -- This method creates the 5skills user session information
  # This method is the MAIN method that is called after the LinkedIn authorization is invoked.
  #
  # --> This method is called once LinkedIn returns with the ACCESS TOKEN and SECRET for this SESSION
  #
  def a_recruiter__init_linkedin_session(access_token, access_secret)
    puts "---- init_linkedin_session"
    
    # Check if the user is registered in the system
    # 1. Get the basic user information from LinkedIn to perform checks on
    # @my_profile = a_recruiter__do_linkedin("my_groups", nil, nil, {:access_token => session[:access_token], :access_secret => session[:access_secret]})
    
    linkedin_token_pair = {:access_token => session[:access_token], :access_secret => session[:access_secret]}
    
    
    # -- 1. User's user information
    
    @my_profile = a_recruiter__do_linkedin("user_information", nil, nil, linkedin_token_pair)
    
    
    # -- X. EXECPTION HANDLING - If for some reason, the LinkedIn connection is broken, redirect to the AUTH page again
    
    if @my_profile.nil?
      
      session[:request_token] = get_linkedin_consumer(3).get_request_token({:oauth_callback => callback_url})
    
      if session[:request_token]
        session[:access_token] = session[:request_token].token
        session[:access_secret] = session[:request_token].secret
      end
      
      # -- Return the 'auth_url' if the method's 'get_aurh_url' flag is set to 'true'
      
      return session[:request_token].authorize_url
      
    end
      
    
    # -- X. Get the USER CONNECTOR object from the LINKEDIN attributes 
    
    if @my_profile[:response_object]['id']
      user_connector = Fs2UserConnector.find_by_linkedin_id(@my_profile[:response_object]['id'])
    elsif @my_profile[:response_object]['emailAddress']
      user_connector = Fs2UserConnector.find_by_linkedin_email(@my_profile[:response_object]['emailAddress'])
    elsif @my_profile[:response_object]['publicProfileUrl']
      user_connector = Fs2UserConnector.find_by_linkedin_email(@my_profile[:response_object]['publicProfileUrl'])
    end
    
    
    # -- X. Update the user connector's TOKENS
    
    if user_connector
      user_connector.update_attributes({
          :linkedin_access_token => access_token,
          :linkedin_access_secret => access_secret
        })
    end
    
    
    # -- X. Check if the user DOES NOT exist in the 'session' object
    
    if session[:user].nil?

      
      # -- X. Check if the SOCIAL CONNECTOR has a 'user_id' assigned to it, if so, get the relevant user
      
      if user_connector && user_connector.user_id # exists in DB
        
        
        # -- X. Find the USER
        
        session[:user] = Fs2User.find_by_id(user_connector.user_id)
        session[:user].update_attribute(:updated_at, Time.new.to_time) # Update the 'updated_at' field
        
        
        # -- X. Find the RECRUITER
        
        recruiter = Fs2Contact.find_by_user_id(user_connector.user_id)
        session[:recruiter_id] = recruiter.id if recruiter
        
        
        # -- X. Locate the LATEST job the Recruiter worked on (first try agent, then company recruiter)
    
        job = Fs2Job.find(:first, :conditions => ["agency_contact_id = ?", recruiter.id], :order => 'updated_at DESC')
        job = Fs2Job.find(:first, :conditions => ["company_contact_id = ?", recruiter.id], :order => 'updated_at DESC') if job.nil?
        session[:job_id] = job.id if job
        session[:job_status_id] = job.status_id if job
        
        
        # -- X. Set up the USER_CONNECTOR object
        
        session[:user_connector_id] = user_connector.id
        
      
      # -- X. Otherwise, create a new USER object
        
      else
        
        
        # -- X. Create the USER object
        
        session[:user] = Fs2User.new({
          :status_id => Fs2User::USER_STATUSES[:linkedin_signed_in], 
          :user_type_id => Fs2User::USER_TYPES[:recruiter],
          :referral_id => session[:user_referral]
        })
        session[:user].email = @my_profile[:response_object]['emailAddress'] if @my_profile[:response_object]['emailAddress']
        session[:user].save(false)
        
        
        # -- X. Create the RECRUITER object
        
        full_name = ""
        full_name += @my_profile[:response_object]['firstName'] if @my_profile[:response_object]['firstName']
        if @my_profile[:response_object]['lastName']
          full_name += " " if !full_name.blank?
          full_name += @my_profile[:response_object]['lastName']  
        end
        
        # -- Save the contact details
        person = Fs2Contact.new({:full_name => full_name})
        person.user_id = session[:user].id
        person.save(false)
        session[:recruiter_id] = person.id
        
        
        # -- X. Create the USER_CONNECTOR object
        
        user_connector = Fs2UserConnector.new({
          :linkedin_access_token => session[:access_token],
          :linkedin_access_secret => session[:access_secret],
          :status_id => 1
          })
        user_connector.user_id = session[:user].id if session[:user]
        user_connector.linkedin_id = @my_profile[:response_object]['id'] if @my_profile[:response_object]['id']
        user_connector.linkedin_email = @my_profile[:response_object]['emailAddress'] if @my_profile[:response_object]['emailAddress']
        user_connector.linkedin_first_name = @my_profile[:response_object]['firstName'] if @my_profile[:response_object]['firstName']
        user_connector.linkedin_last_name = @my_profile[:response_object]['lastName'] if @my_profile[:response_object]['lastName']
        user_connector.linkedin_public_profile_url = @my_profile[:response_object]['publicProfileUrl'] if @my_profile[:response_object]['publicProfileUrl']
        user_connector.save(false)
        session[:user_connector_id] = user_connector.id
        
      end
      
    end
    
  
    # ----
    # ----
    # COLLECT ADDITIONAL LINKEDIN INFORMATION --> COMPANIES + GROUPS
    
      
    # -- X. Find the current positions
    
    if @my_profile[:response_object]['positions'] && @my_profile[:response_object]['positions']['values']
      current_positions = @my_profile[:response_object]['positions']['values'].select { |c| c['isCurrent'] == true && c['company'] }
      current_company_ids = current_positions.collect { |p| p['company']['id'] if p['company'] }
    end
    
    # -- 2. User's current companies' details & groups
    
    @my_company_details = a_recruiter__do_linkedin("user_company_information", {:company_ids => current_company_ids}, nil, linkedin_token_pair)
    my_groups = a_recruiter__do_linkedin("my_groups", {:company_ids => current_company_ids}, nil, linkedin_token_pair)
    
    
    # -- 3. Sync the user's publishing groups
    
    user_groups = my_groups[:response_object]['values'].collect { |group| [ group['_key'], group['membershipState']['code'] ] }
    sync_user_publishing_channels(session[:user].id, user_groups)
    
    
    # -- 4. Update the 5skills LinkedIn groups information (logo, id, etc)
    
    # 'nil' is used as 2nd parameter as it is normally used for recording the 'missing' groups information
    _insert_update_channels_table(my_groups, nil)
      
    
    # COMPANIES + GROUPS  
    # ----
    # ----
  
    
    
    # -- X. Locate the SKILLS PROFILE if it exists in DB
    # NEEDS TESTING
    
    # skills_profile = Fs2SkillsProfile.find(:first, :conditions => 
      # ["profile_type = ? AND entity_type = ? AND entity_id = ?", 
      # FS_PROFILE_TYPES[:user_profile], ENTITY_TYPES[:job], session[:recruiter_id]]) if session[:recruiter_id]
    # session[:skills_profile_id] = skills_profile.id if skills_profile
    
    # @my_profile[:response_object]
    
    
    return nil
    
  end
  
  
  #
  # Parameters:
  # --
  # s
  # 're_auth_actions' -> 
  #   [:accept]
  #   [:cancel]
  #
  def a_recruiter__init_linkedin_tokens(re_auth_actions, get_auth_url = false)
    
    
    # -- PROCESS
    # 1. Check session object for 'user' and 'user_connector' -> get the LinkedIn keys
    # 2. [found] attempt to make a basic call (validate the tokens and permissions)
    #     [successful] Redirect to funnel step (either publish job or job publishing home)
    #     [unsuccessful] Redirect to callback_url
    # 3. [not found]
    #     Redirect to callbak_url (authorization)
    
    
    callback_url = linkedin_auth_accept_url
    
    
    # -- Construct the 'accept' and 'cancel' based on the 're_auth_action's parameter
     
    re_auth_querys = ""
    
    if re_auth_actions && (re_auth_actions[:accept] || re_auth_actions[:cancel])
      re_auth_querys = re_auth_querys + "?"
      if re_auth_actions[:accept]
        re_auth_querys = re_auth_querys + "ra_a=" + re_auth_actions[:accept]
        re_auth_querys = re_auth_querys + "&" if re_auth_actions[:cancel]
      end
      re_auth_querys = re_auth_querys + "ra_c=" + re_auth_actions[:cancel] if re_auth_actions[:cancel]
    end
    
    
    # -- Addition for the 'a_recruiter' implementation
    # callback_url = callback_url + re_auth_querys
    callback_url = callback_url + "?a_recruiter=true"
    
    
    # -- Create the REQUEST TOKEN
    
    # session[:request_token] = get_linkedin_consumer().get_request_token({:oauth_callback => callback_url})
    
    
    # -- 1. Get a FRESH request token from the LinkedIn consumer
    # Store it in SESSION
    session[:request_token] = get_linkedin_consumer(3).get_request_token({:oauth_callback => callback_url})
    
    # -- 2. Set the SESSION - TOKEN and SECRET attributes
    if session[:request_token]
      session[:access_token] = session[:request_token].token
      session[:access_secret] = session[:request_token].secret
    end
    
    
    # -- Try and perform a basic linkedin_call to verify if the right permissions exist
    
    # @my_profile = a_recruiter__do_linkedin("my_groups", nil, nil, {:access_token => session[:access_token], :access_secret => session[:access_secret]})
    
    
    # -- Return the 'auth_url' if the method's 'get_aurh_url' flag is set to 'true'
    
    session[:request_token].authorize_url if get_auth_url
    
  end
  
  
  # 
  # This method will
  #
  def init_linkedin_tokens(re_auth_actions, get_auth_url = false)
    
    callback_url = linkedin_auth_accept_url
    # callback_url = callback_url + "?rk=" + rk if rk
    
    
    # -- Construct the 'accept' and 'cancel'
     
    re_auth_querys = ""
    
    if re_auth_actions && (re_auth_actions[:accept] || re_auth_actions[:cancel])
      re_auth_querys = re_auth_querys + "?"
      if re_auth_actions[:accept]
        re_auth_querys = re_auth_querys + "ra_a=" + re_auth_actions[:accept]
        re_auth_querys = re_auth_querys + "&" if re_auth_actions[:cancel]
      end
      re_auth_querys = re_auth_querys + "ra_c=" + re_auth_actions[:cancel] if re_auth_actions[:cancel]
    end
    
    callback_url = callback_url + re_auth_querys
    
    # -- Create the REQUEST TOKEN
    
    session[:request_token] = get_linkedin_consumer().get_request_token({:oauth_callback => callback_url})
    
    if session[:request_token]
      session[:access_token] = session[:request_token].token
      session[:access_secret] = session[:request_token].secret
    end
    
    # -- Return the 'auth_url' if the method's 'get_aurh_url' flag is set to 'true'
    
    session[:request_token].authorize_url if get_auth_url
    
  end
  
  def do_linkedin_login()
    
    puts "---- do_linkedin_login"
    
    auth_url = init_linkedin_tokens(nil, true)
    
    redirect_to auth_url
    
  end
  
  def a_recruiter__do_linkedin_login()
    
    puts "---- do_linkedin_login"
    
    auth_url = a_recruiter__init_linkedin_tokens(nil, true)
    
    redirect_to auth_url
    
  end  
    
  

  
  def linkedin_auth_accept
    puts "---- linkedin_auth_accept: redirect_key - '" + params[:rk].to_s + "'" 
    
    # First time, get the access token and store the 'access_token.token' and 'access_token.secret' in the database
    access_token = session[:request_token].get_access_token(:oauth_verifier => params[:oauth_verifier])
    session[:access_token] = access_token.token
    session[:access_secret] = access_token.secret
    
    # do_linkedin_login if init_linkedin_session(access_token.token, access_token.secret).nil?
    
    
    # -- Third attempt, redirecting to an AJAX call
    
    if params[:ra_a]
      
      @func_attrs = params[:ra_a].split(",")
      
      render '/five_skills/__connector.html', :layout => "__basic_layout"
    
    
    # -- Second attempt at redirecting back to a specific page  
    
    elsif params[:rk]
    
      if params[:rk].to_i == 1
        redirect_to :action => :recruiter_home, :controller => :fs_job, :page => 'social'
      elsif params[:rk].to_i == 2
        render '/five_skills/__connector.html', :layout => "__basic_layout" 
      else
        redirect_to :action => :recruiter_home, :controller => :fs_job
      end
      
     
    # -- A RECRUITER - FEB 2014
    
    elsif params[:a_recruiter] && params[:a_recruiter] == "true"
      
      a_recruiter__init_linkedin_session(access_token.token, access_token.secret)
      # _recruiter_routing
      redirect_to :action => :a_recruiter_publish_job, :controller => :fs_job
      
      
    # -- Original, NO-AJAX redirect system
    
    else
      
      init_linkedin_session(access_token.token, access_token.secret)
      
      redirect_to :action => :view_seeker_profile, :controller => :fs_job_seeker
      
    end
  end
  
  
  
  # 
  # Permission types:
  #  1 - All inclusive
  #  2 - No connections
  #
  def get_linkedin_consumer(permission_type = 3)
    
    case permission_type
      when 1 # Full profile WITH connections
        configuration = { :site => 'https://api.linkedin.com',
          :authorize_path => '/uas/oauth/authenticate',
          :request_token_path => '/uas/oauth/requestToken?scope=r_fullprofile+r_emailaddress+r_network+r_contactinfo+rw_groups',
          :access_token_path => '/uas/oauth/accessToken' }
          
      when 2 # Full profile WITHOUT connections
        configuration = { :site => 'https://api.linkedin.com',
          :authorize_path => '/uas/oauth/authenticate',
          :request_token_path => '/uas/oauth/requestToken?scope=r_fullprofile+r_emailaddress+r_contactinfo+rw_groups',
          :access_token_path => '/uas/oauth/accessToken' }
          
      when 3 # GROUPS (with Full profile)
        configuration = { :site => 'https://api.linkedin.com',
          :authorize_path => '/uas/oauth/authenticate',
          :request_token_path => '/uas/oauth/requestToken?scope=r_fullprofile+r_emailaddress+r_contactinfo+rw_groups+rw_nus',
          :access_token_path => '/uas/oauth/accessToken' }
    end
     
    OAuth::Consumer.new(LINKEDIN_API_KEY, LINKEDIN_API_SECRET, configuration)
        
  end
  
  
  def a_recruiter__do_linkedin(type,
      data = nil,
      re_auth_actions = nil, 
      access_keys = {:access_token => nil, :access_secret => nil})
      
        if session[:user]
          access_keys = {:access_token => session[:access_token], :access_secret => session[:access_secret]}
        end
      
        do_linkedin(type, data, re_auth_actions, access_keys)
          
  end
  
  
  # --- Main LINKEDIN API calls
  #
  def do_linkedin(
      type,
      data = nil,
      re_auth_actions = nil, 
      access_keys = {:access_token => session[:access_token], :access_secret => session[:access_secret]})

      
    # -- Re-authenticate to the default 'recruiter_home' in case the user doesn't have valid ACCESS_KEYS
    raise APIAuthError.new if access_keys[:access_token].nil? || access_keys[:access_secret].nil? 
    
    # -- Convert an INTEGER 'type' to a STRING 'type' for processing
    type = LINKEDIN_CALLS[type] if type.is_a? Integer
    callback_action = nil
    
    # -- Log    
    puts "---- do_linkedin: " + type.to_s + " ; " + access_keys[:access_token].to_s + "/" + access_keys[:access_secret].to_s
    
    
    # -- EXECUTE LINKEDIN APIs
    
    case type
      
      
      # ---------------- PROFILE INFORMATION ----------------
      
      
      when "my_profile"
        
        access_token = OAuth::AccessToken.new(get_linkedin_consumer(3), access_keys[:access_token], access_keys[:access_secret])
        response = access_token.get("http://api.linkedin.com/v1/people/~:(id,first-name,last-name,email-address,public-profile-url)?format=json")
        return _handle_response(response)
        
        
      when "my_profile__no_connections"
        
        access_token = OAuth::AccessToken.new(get_linkedin_consumer(2), access_keys[:access_token], access_keys[:access_secret])
        response = access_token.get("http://api.linkedin.com/v1/people/~:(id,first-name,last-name,email-address,public-profile-url,headline,location:(name,country:(code)),industry,skills,positions,educations)?format=json")
        return _handle_response(response)
        
        
      when "my_profile__with_connections"
        
        access_token = OAuth::AccessToken.new(get_linkedin_consumer(1), access_keys[:access_token], access_keys[:access_secret])
        response = access_token.get("http://api.linkedin.com/v1/people/~:(id,first-name,last-name,email-address,headline,location:(name,country:(code)),industry,skills,positions,educations,connections:(id,first-name,last-name,email-address,industry,skills,positions,public-profile-url))?format=json")
        return _handle_response(response)
            
            
      # ---------------- GROUPS ----------------
      
      when "user_information"
        response = li__get_user_information(access_keys)
        callback_action = "get_user_information"
        
      
      when "user_company_information"
        response = li__get_company_information(access_keys, data)
        callback_action = "get_company_information"
            
            
      when "my_groups"
        
        response = li__my_groups(access_keys)
        callback_action = "get_linkedin_groups"
        
        
      when "post_to_single_group"
        
        response = li__post_to_single_group(access_keys)
        callback_action = "publish_job"
      
      
      # -- Get the groups that I need to publish to (including ones I am not a member of currently)
      #
      when "my_job__publishing_groups"
        
        response = li__my_job__publishing_groups(access_keys, data)
        callback_action = "get_job_publishing_info"
        
        
      # -- Publish the job
      #
      when "publish_my_job"
        
        response = li__publish_my_job(access_keys, data)
        callback_action = "a_recruiter__publish_job"
      
      
      # ---------------- DEPRECATED ----------------
      when 2
        response = access_token.get("http://api.linkedin.com/v1/people/~:connections:(id,first-name,last-name,email-address,industry,skills,positions)?format=json")
      when 3 # CONNECTIONS
        response = access_token.get("http://api.linkedin.com/v1/people/id=VRfvN4Sueg:(id,first-name,last-name,email-address,headline,location:(name,country:(code)),industry,skills,positions,educations,connections:(id,first-name,last-name,email-address,industry,skills,positions)?format=json")
      # ---------------- DEPRECATED ----------------
               
    end
    
    
    # -- SUCCESS
    
    return {
      :status => "200",
      :action => callback_action,
      :message => "Successfully saved profile!"
    }.merge(response)
    
    
    # -- FAILED AUTHENTICATION
    
  rescue APIAuthError => exc
    return construct__auth_error_arr(callback_action, re_auth_actions)
    
  end
  
  def _construct_sql_value(value)
    if value.is_a? String
      _sql_value = "'" + escape_single_quotes(value) + "'"
    elsif value.nil?
      _sql_value = "''"
    else
      _sql_value = value.to_s
    end
    
    _sql_value
  end
    
  # -- 
  #
  # 'where_update_fields' - An array of the field to find by [0] and the fields to update [1] onwards
  #   -> e.g. [ 'id', 'publishing_channel_id', 'channel_status' ]
  #
  # 'where_update_values' - a 2-dimensional array
  #   (1st) array is of row's data
  #   (2nd) array has at [0] the 'where_field' match and [1] onwards, the data to fit the row
  #
  #   EXAMPLE: [ [ 106, 17, 'awaiting confirmation' ], [ 107, 18, 'member' ], [ 108, 19, 'owner' ] ]
  #
  def _construct_multiple_update_sql(table, where_update_fields, where_update_values)
    id_collector = Array.new
    update_sql = "UPDATE #{table} SET"
    
    (where_update_fields.length - 1).times do |field_i|
      update_sql += ", " if field_i > 0
      update_sql += " #{where_update_fields[field_i + 1]} = CASE #{where_update_fields[0]}"
      
      where_update_values.each_index do |i|
        update_sql += " WHEN " + _construct_sql_value(where_update_values[i][0]) + " THEN " + _construct_sql_value(where_update_values[i][field_i + 1])
        id_collector << _construct_sql_value(where_update_values[i][0]) if field_i == 0
      end
      
      update_sql += " END"
    end
    
    update_sql += " WHERE #{where_update_fields[0]} in (" + id_collector.join(",") + ")"
      
    update_sql
  end
  
  
  # -- 'table' -> Table name
  # -- 'fields' -> Array of field names
  # -- 'rows' -> Array of rows to be inserted (2 dimensional array)
  #
  def _construct_multiple_insert_sql(table, fields, rows)
    
    return nil if table.nil? || fields.nil? || rows.nil?
    
    insert_sql = "insert into #{table} ( #{fields.join(", ")} ) values"
    x = 0
    
    rows.each do |row|
      insert_sql += "," if x > 0
      insert_sql += " ("
      y = 0
      
      row.each do |value|
        insert_sql += "," if y > 0
        insert_sql += _construct_sql_value(value)
        y += 1
      end
      
      insert_sql += ")"
      
      x += 1
    end
    
    insert_sql
    
  end
  
  def linkedin_auth_cancel
    redirect_to :action => :view_seeker_profile, :controller => :fs_job_seeker
  end
  
  
  # -- BASELINE permissions check
  #
  def li__get_user_information(access_keys)
    access_token = OAuth::AccessToken.new(get_linkedin_consumer(3), access_keys[:access_token], access_keys[:access_secret])
    json_groups = _get_linkedin(access_token, "people/~:(id,first-name,last-name,email-address,public-profile-url,headline,location:(name,country:(code)),positions,num-connections,picture-url,group-memberships)?format=json")
    
    json_groups
  end
  
  
  # -- BASELINE permissions check
  #
  def li__get_company_information(access_keys, data)
    access_token = OAuth::AccessToken.new(get_linkedin_consumer(3), access_keys[:access_token], access_keys[:access_secret])
    
    json_companies = _get_linkedin(access_token, "companies::(#{data[:company_ids].join(',')}):(id,name,description,email-domains,company-type,website-url,industries,logo-url,square-logo-url,locations,specialties)?format=json")
    
    json_companies
  end  
  
  
  # --
  # Retrieve the user's current linkedin groups
  # 
  def li__my_groups(access_keys)
    access_token = OAuth::AccessToken.new(get_linkedin_consumer(3), access_keys[:access_token], access_keys[:access_secret])
    
    
    # -- X. WITH 'posts' -> to be used as part of automatically determining the location of the group (for targeted groups)
    # json_groups = _get_linkedin(access_token, "people/~/group-memberships:(group:(id,name,num-members,short-description,small-logo-url,large-logo-url,website-url,site-group-url,posts,counts-by-category,locale,location),membership-state)?format=json&start=0&count=1000")
    
    
    # -- X. WITHOUT 'posts'
    json_groups = _get_linkedin(access_token, "people/~/group-memberships:(group:(id,name,num-members,short-description,small-logo-url,large-logo-url,website-url,site-group-url,counts-by-category,locale,location),membership-state)?format=json&start=0&count=1000")
    
    
    # response = access_token.get("http://api.linkedin.com/v1/people/~/group-memberships:(group:(id,name,num-members,small-logo-url),membership-state,show-group-logo-in-profile,allow-messages-from-members,email-digest-frequency,email-announcements-from-managers,email-for-every-new-post)?format=json&start=0&count=1000")
    # response = access_token.get("http://api.linkedin.com/v1/groups::(5049608,5112233,5161898):(id,name,site-group-url,posts)?format=json")
    
    json_groups
  end  
  
  
  #
  # This method returns the REQUIRED channels based on one of the following objects:
  #   1. fs_profile --> aggregate the categories that relate to all the fs_profile skills
  #   2. category --> skill_category (not implemented yet)
  #
  def _get_required_channels(by_what, using_values)
    
    return nil if by_what.nil? || using_values.nil?
    
    case by_what
      
      when "by_fs_profile_id"
        
        _required_channels = Fs2PublishingChannel.find(
          :all, 
          :conditions => [ "category_id = ?", 1])
          
      when "by_category_id"
        
        _required_channels = Fs2MapSkillToPublishingChannel.find(
          :all, 
          :joins => ["LEFT JOIN `fs2_publishing_channels` ON fs2_publishing_channels.id = fs2_map_skill_to_publishing_channels.publishing_channel_id"],
          :select => "fs2_publishing_channels.*")
          
      when "by_channel_ids"
        
        _required_channels = Fs2PublishingChannel.find(
          :all, 
          :conditions => [ "channel_id in (?) AND platform = ? AND channel_type = ?", using_values, 'LinkedIn', 'Group'])
      
    end
    
    # 3 5skills test groups
    # required_groups = ["5049608", "5112233", "5161898"]
    
    # _required_channels.collect { |e| e[:channel_id] } if _required_channels
    
    _required_channels_h = {}
    _required_channels.each { |e| _required_channels_h[e[:channel_id]] = e }
    
    _required_channels_h
    
  end
  
  def _get_required_member_groups
    
    # 3 5skills test groups
    required_member_groups = ["5112233", "5161898"]
    
    required_member_groups
    
  end
  
  def _get_missing_groups
    
    # 3 5skills test groups
    missing_groups = ["5049608"]
    
    missing_groups
    
  end
  
  
  def li__my_job__publishing_groups(access_keys, data)
    
    access_token = OAuth::AccessToken.new(get_linkedin_consumer(3), access_keys[:access_token], access_keys[:access_secret])
    required_channels = data[:required_channels]
    
    # -- 1 - Obtain all groups the member is part of using the following, the API returns only groups the member is part of
    
    # current_member_groups = access_token.get("http://api.linkedin.com/v1/people/~/group-memberships:(group:(id,name,num-members,small-logo-url),membership-state,show-group-logo-in-profile,allow-messages-from-members,email-digest-frequency,email-announcements-from-managers,email-for-every-new-post)?format=json&start=0&count=1000")
    json_groups = _get_linkedin(access_token, "people/~/group-memberships:(group:(id,name,num-members,short-description,small-logo-url,large-logo-url,website-url,site-group-url),membership-state)?format=json&start=0&count=1000")
    
    
    # -- 2 - Construct an ARRAY of the required 'missing groups'
    
    my_required_groups = json_groups[:response_object]['values'].select { |e| required_channels[e['_key']] } if json_groups[:response_object]['values']
    my_required_group_keys = my_required_groups.collect { |e| e['_key'] } if my_required_groups
    
    my_missing_group_keys = required_channels.keys - my_required_group_keys  # '-' returns the opposite of the UNION operation ('&')
    my_missing_groups = [] if my_missing_group_keys.length > 0
    
    # -- 3 - Iterate through all 'missing' groups and retrieve their current status
    
    my_missing_group_keys.each do |group_key|
      # api_response = access_token.get("http://api.linkedin.com/v1/groups/#{group_key}:(id,name,short-description,description,relation-to-viewer:(membership-state,available-actions),posts,counts-by-category,is-open-to-non-members,category,website-url,locale,location:(country,postal-code),allow-member-invites,site-group-url,small-logo-url,large-logo-url)?format=json")
      api_response = _get_linkedin(access_token, "groups/#{group_key}:(id,name,num-members,short-description,relation-to-viewer:(membership-state,available-actions),posts,counts-by-category,category,website-url,site-group-url,locale,location:(country,postal-code),small-logo-url,large-logo-url)?format=json")
      my_missing_groups << api_response
    end
    
    
    # -- * - Make sure the groups table PUBLISHING CHANNELS is up-to-date (MEMBER and NON-MEMBER ones)
    _insert_update_channels_table(json_groups, my_missing_groups)
    
    
    {
      :job__publishing_info => {
        :required_groups => {
          :_total => my_required_groups.length,
          :values => my_required_groups
        },
        :missing_groups => {
          :_total => my_missing_groups.length,
          :values => my_missing_groups
        }
      }
    }
    
  end
  
  
  # -- This method refreshes the group information stored in 5skills (name, url etc) so display is faster
  #
  def _insert_update_channels_table(my_current_groups, my_missing_groups)
    
    data_fields_arr = [ 'id', 'platform', 'channel_type', 'channel_id', 'channel_name', 
      'short_description', 'website_url', 'site_group_url', 'small_logo_url', 'large_logo_url', 'num_members' ]
    data_insert_values_arr = []
    data_update_values_arr = []
    
    # -- Try and find the relevant groups / channels
    stored_channels = Fs2PublishingChannel.find(
      :all,
      :select => "id, channel_id",
      :conditions => ["platform = ? AND channel_type = ?", "LinkedIn", "Group"] )
    
    stored_channels = stored_channels.inject({}){ |hash, channel| hash[channel.channel_id] = channel; hash }
      
    if my_current_groups[:response_object]['values']
     
      my_current_groups[:response_object]['values'].select do |e|
        
        
        # -- UPDATE,  if the DB channel ID matches the LinkedIn channel ID ---> MATCH ---> Update
        if stored_channels && !stored_channels.empty? && stored_channels[e['group']['id']] 
        
          data_update_values_arr <<
            [ stored_channels[e['group']['id']].id, 'LinkedIn', 'Group', e['group']['id'], e['group']['name'], 
            e['group']['shortDescription'], '', e['group']['siteGroupUrl'],
            e['group']['smallLogoUrl'], e['group']['largeLogoUrl'], e['group']['numMembers'].to_i ]


        # -- CREATE
        else
          
          data_insert_values_arr <<
            [ 'LinkedIn', 'Group', e['group']['id'], e['group']['name'], 
            e['group']['shortDescription'], '', e['group']['siteGroupUrl'],
            e['group']['smallLogoUrl'], e['group']['largeLogoUrl'], e['group']['numMembers'].to_i ]
            
        end     
        
        stored_channels.delete(e['group']['id'])
        
      end
      
    end
    
    if my_missing_groups
      
      my_missing_groups.select do |e|
        
        
        # -- UPDATE,  if the DB channel ID matches the LinkedIn channel ID ---> MATCH ---> Update
        if stored_channels && !stored_channels.empty? && stored_channels[e[:response_object]['id']] 
        
          data_update_values_arr <<
            [ stored_channels[e[:response_object]['id']].id, 'LinkedIn', 'Group', e[:response_object]['id'], e[:response_object]['name'],
            e[:response_object]['shortDescription'], '', e[:response_object]['siteGroupUrl'],
            e[:response_object]['smallLogoUrl'], e[:response_object]['largeLogoUrl'], e[:response_object]['numMembers'] ]


        # -- CREATE
        else
          
          data_insert_values_arr <<
            [ 'LinkedIn', 'Group', e[:response_object]['id'], e[:response_object]['name'],
            e[:response_object]['shortDescription'], '', e[:response_object]['siteGroupUrl'],
            e[:response_object]['smallLogoUrl'], e[:response_object]['largeLogoUrl'], e[:response_object]['numMembers'] ]
            
        end     
        
        stored_channels.delete(e[:response_object]['id'])
        
      end
      
    end
    
    
    # UPDATE - DB calls
    if data_update_values_arr && !data_update_values_arr.empty?
      _sql_update = _construct_multiple_update_sql('fs2_publishing_channels', data_fields_arr, data_update_values_arr )
      Fs2PublishingChannel.connection.execute(_sql_update)
    end
    
    # CREATE - DB calls
    if data_insert_values_arr && !data_insert_values_arr.empty?
      _sql_insert = _construct_multiple_insert_sql( 'fs2_publishing_channels', data_fields_arr.drop(1), data_insert_values_arr)
      Fs2PublishingChannel.connection.execute(_sql_insert)
    end
    
  end
  
  
  
  # -- Perform the publishing of the job
  #
  # @ March, 2014
  #
  # Needed parameters:
  #  - params[:user_id]
  #  - params[:job_id]
  #  - required_channels --> 999999
  #     --> 'fs2_map_skill_to_publishing_channels' table --> maps category '999999' (test category)
  #     --> to 'publishing_channels' 16, 17, 18 (5skills test groups)
  #
  def li__publish_my_job(access_keys, data)
    
    
    # -- X. Expected 'data'
    #  1. :selected_groups
    #
    
    
    # ------ 1 - Get the consumer
          
    access_token = OAuth::AccessToken.new(get_linkedin_consumer(3), access_keys[:access_token], access_keys[:access_secret])
    user_id = params[:user_id]
    job_id = params[:job_id]
    job = nil
    
    # ------ 2 - Create the post
    
    _host = request.env["HTTP_HOST"]
    _production_host = "5skills.me"
    
    if job_id
      
      job_profile = fetch_job_profile(job_id.to_i)
      job = job_profile[:job_obj]
    
    # -- HARD CODING  
    else
      
      _host = request.env["HTTP_HOST"]
      
      if _host == 'localhost:3000' # local
        # job = Fs2Job.find_by_id(164)
        job = Fs2Job.find_by_id(100)
      else # remote
        job = Fs2Job.find_by_id(100)
      end
      
    end

        
    posts = {}
    posts_for_db = []
    
    
    # -- 1 - Post to the wall -> WALL POST
    
    
    # -- X. Prep the logo (determine if it's the company's or the agency's)
    
    # watermark_xy_coords = [5, 5]
    watermark_xy = [-20, -5]
    uploaded_image_watermarked = "http://res.cloudinary.com/fiveskills/image/upload/w_180,h_110,c_fit/l_5skills_logo,w_15,g_south_east,x_#{watermark_xy[0].to_s},y_#{watermark_xy[1].to_s}/"
    
    if job_profile[:agency_files] && job_profile[:agency_files][:agency_logo]
      uploaded_image_watermarked += job_profile[:agency_files][:agency_logo].id.to_s + "_w" + "." + "png"
      
    elsif job_profile[:company_files] && job_profile[:company_files][:company_logo]
      uploaded_image_watermarked += job_profile[:company_files][:company_logo].id.to_s + "_w" + "." + "png"
      
    end
    
    
    # -- X. Prep the recruiting company name

    if job_profile[:agency_obj] && job_profile[:agency_obj][:name]
      recruiting_company__name = job_profile[:agency_obj][:name]
      
    elsif job_profile[:company_obj] && job_profile[:company_obj][:name]
      recruiting_company__name = job_profile[:company_obj][:name]
      
    end
    
    
    # -- X. Upload the job's logo to the cloud
    
    # Sample real-time transformation:
    #   Intel logo with 5skills watermark on it
    #   https://res.cloudinary.com/fiveskills/image/upload/w_100,h_80,c_fill/l_5skills_logo,w_15,g_south_east,x_5,y_5/Intel-logo_eweqyw.png
    # Tutorial
    #   http://cloudinary.com/blog/adding_watermarks_credits_badges_and_text_overlays_to_images
    
    # uploaded_image_raw = Cloudinary::Uploader.upload(recruiting_company_logo_url)


    post_params = {
      :job => {
        :id => job_id,
        :comment => "#{recruiting_company__name} is hiring!",
        :title => job[:title],
        :teaser => job[:teaser] + "_ Test",
        :submitted_url => "http://" + _host + "/a/recruiter/job_post/",
        :submitted_image_url => uploaded_image_watermarked 
      }, :channels => {
        :wall => nil,
        :groups => nil
      },
      :user_id => user_id,
      :access_token => access_token
    }
    
    
    # -- X - WALL CHECK
    
    post_params[:channels][:wall] = true if data[:selected_groups].include?("-1")
    
    
    # -------------------------------------------------- WALL --------------------------------------------------
     
    if post_params[:channels][:wall]
      
      _res = li__publish_my_job__post_to_wall(post_params)
      # _res = UNIT__li__publish_my_job__post_to_wall(post_params)
    
      # Merge the response with the main 'posts' hash
      posts.merge!(_res[:posts])
      posts_for_db.concat(_res[:posts_for_db])
      
    end
      
      
    # -------------------------------------------------- GROUPS --------------------------------------------------
    
    # - Get required channels
    # post_params[:channels][:groups] = _get_required_channels("by_category_id", 999999)
    
    # - Get channels by selected groups
    post_params[:channels][:groups] = _get_required_channels("by_channel_ids", data[:selected_groups])
    
    
    _res = li__publish_my_job__post_to_groups(post_params)
    
    # Merge the response with the main 'posts' hash
    posts.merge!(_res[:posts])
    posts_for_db.concat(_res[:posts_for_db])
    
    
    # -------------------------------------------------- UPDATE DATABASE --------------------------------------------------
    
      
    # -- Iterate through all POST channel information and ADD channel information (from 5skills' DB)
    posts.each do |ch_key, ch_obj|
      next if ch_key == :wall
      
      posts[ch_key][:group_info] = post_params[:channels][:groups][ch_key].attributes
    end
      
      
    _sql_insert = _construct_multiple_insert_sql(
      'fs2_job_publishing_posts',
      [ 'user_id', 'job_id', 'publishing_channel_id', 'post_key', 'post_type', 'status',
        'title', 'summary', 'content_submitted_url', 'content_submitted_image_url', 'content_title', 'content_description', 
        'ref_key', 'api_response_code', 'api_response_message', 'api_response_body', 'created_at'],
      posts_for_db)
    Fs2JobPublishingPost.connection.execute(_sql_insert)

    
    # Return the CONSTRUCT
    {
      :post_channels => {
        :linkedin => posts
      }
    }
    
  end
  
  
  def li__publish_my_job__post_to_groups(post_params)
    
    
    # -- X. Initialize
    
    posts = {}
    posts_for_db = []
    
    
    post_params[:channels][:groups].each do |ch_key, ch_obj|
      
      # channel_id_collector << ch_obj.id
      posts[ch_key] = {}
    

      # -------------------------------------------------- SINGLE DISCUSSION --------------------------------------------------
      
      # -- 2 - Post a DISCUSSION (before flagging it as a job) -> JOB DISCUSSION
      
      # Create the unique KEY (for CTR tracking)
      ref_key = Digest::SHA2.hexdigest(ch_obj.id.to_s + "Group" + post_params[:job][:id].to_s + ActiveSupport::SecureRandom.base64(8))
      
      job_discussion_post = {
        :title => post_params[:job][:title],
        :summary => post_params[:job][:teaser],
        :content => {
           :submitted_url => post_params[:job][:submitted_url] + ref_key,
           :submitted_image_url => post_params[:job][:submitted_image_url],
           :title => "APPLY NOW",
           :description => "Apply with your skills. Not your CV."
          }
      }
      
      _api_job_discussion_post = job_discussion_post.to_xml(:root => 'post', :skip_instruct => true).to_s
      posts[ch_key][:discussion] = _post_linkedin(post_params[:access_token], "groups/#{ch_key}/posts", _api_job_discussion_post)
      
      
      # ** Prep-DB storing information
        
      
      # Post ID
      post_id = ''
      published = false
      if posts[ch_key][:discussion] && posts[ch_key][:discussion][:response_http_object] && posts[ch_key][:discussion][:response_http_object]['location']
        post_id = posts[ch_key][:discussion][:response_http_object]['location'].split("/").last
        posts[ch_key][:discussion][:post_id] = post_id
        published = true
      end
      
      # Status
      if posts[ch_key][:discussion][:response_http_object].code == '200' ||
        posts[ch_key][:discussion][:response_http_object].code == '201' ||
        posts[ch_key][:discussion][:response_http_object].code == '204'
          posts[ch_key][:status_id] = 1 # For the client display
          post_status = 'Published'
      else
        posts[ch_key][:status_id] = 3 # For the client display
        post_status = 'Failed'
      end
      
      # -- A - Add discussion to the database
    
      posts_for_db << [
        post_params[:user_id], post_params[:job][:id], ch_obj.id, post_id, 'Discussion', post_status,
        escape_single_quotes(job_discussion_post[:title]),
        escape_single_quotes(job_discussion_post[:summary]),
        job_discussion_post[:content][:submitted_url],
        job_discussion_post[:content][:submitted_image_url],
        escape_single_quotes(job_discussion_post[:content][:title]),
        escape_single_quotes(job_discussion_post[:content][:description]),
        ref_key,
        posts[ch_key][:discussion][:response_http_object].code,
        posts[ch_key][:discussion][:response_http_object].message.to_s,
        escape_single_quotes(posts[ch_key][:discussion][:response_http_object].body),
        Time.now.to_datetime.strftime("%F %T")
      ]
        
        
        
      # -------------------------------------------------- JOB DISCUSSION --------------------------------------------------
      
      # -- 4 - Flag the post as a JOB DISCUSSION ('put') using the 'location' attribute
      
      if published
        
        li_job_code = "<code>job</code>"
        posts[ch_key][:job_discussion] = _put_linkedin(post_params[:access_token], "posts/#{post_id}/category/code", li_job_code)
        
        # Status
        if posts[ch_key][:job_discussion][:response_http_object].code == '200' ||
          posts[ch_key][:job_discussion][:response_http_object].code == '201' ||
          posts[ch_key][:job_discussion][:response_http_object].code == '204'
            post_status = 'Modified'
            
          # Add the POST_ID attribute
          posts[ch_key][:job_discussion][:post_id] = post_id            
        else
          post_status = 'Failed'
        end
        
        posts_for_db << [
          post_params[:user_id], post_params[:job][:id], ch_obj.id, post_id, 'Job discussion', post_status,
          '',
          '',
          '',
          '',
          '',
          '',
          ref_key,
          posts[ch_key][:job_discussion][:response_http_object].code,
          posts[ch_key][:job_discussion][:response_http_object].message.to_s,
          escape_single_quotes(posts[ch_key][:job_discussion][:response_http_object].body.to_s),
          Time.now.to_datetime.strftime("%F %T")
        ]
        
      end
      
    end    
    
    
    {:posts => posts, :posts_for_db => posts_for_db}
    
  end
  
  
  #
  # -- X - UNIT TESTING
  #
  def UNIT__li__publish_my_job__post_to_wall(post_params)
    
    
    posts = {}
    posts_for_db = []
    
    wall_channel_id = Fs2PublishingChannel.find(:first, :conditions => [ "platform = ? AND channel_type = ?", 'LinkedIn', 'Wall'])
    wall_channel_id = wall_channel_id.id if wall_channel_id
    
    ref_key = Digest::SHA2.hexdigest(wall_channel_id.to_s + "Wall" + post_params[:job][:id].to_s + ActiveSupport::SecureRandom.base64(8))
    
    # -- The response object, returned after the LinkedIn call
    posts["-1"] = {
      :request_url => "",
      :status_id => 1,
      :status => "retrieved_successfully",
      :request_xml => "blah",
      :response_object => {
        :update => {
          :update_url => "http://linkedin.com/the_post"
        }
      },
      :response_http_object => {
        :code => 200,
        :message => "Success",
        :body => "TEST - success"
      }
    }
    
    # Status
    post_id = ''
    post_status = 'Published'
    # post_status = 'Failed'
    
    
    posts_for_db << [
        post_params[:user_id], post_params[:job][:id], wall_channel_id, post_id, 'Wall', post_status,
        escape_single_quotes(post_params[:job][:comment]),
        '',
        post_params[:job][:submitted_url] + ref_key,
        post_params[:job][:submitted_image_url],
        escape_single_quotes(post_params[:job][:title]),
        escape_single_quotes(post_params[:job][:teaser]),
        ref_key,
        posts["-1"][:response_http_object][:code],
        posts["-1"][:response_http_object][:message].to_s,
        escape_single_quotes(posts["-1"][:response_http_object][:body]),
        Time.now.to_datetime.strftime("%F %T")
      ]
      
    
    {:posts => posts, :posts_for_db => posts_for_db}
    
    
  end 
    
    
  
  
  #
  # IN
  # ---
  #   post_params
  #
  # OUT
  # ----
  #   {:posts, :posts_for_db}
  #
  def li__publish_my_job__post_to_wall(post_params)
    
    
    # -- X. Initialize
    
    posts = {}
    posts_for_db = []
    post_id = ''
    
    
    wall_channel_id = Fs2PublishingChannel.find(:first, :conditions => [ "platform = ? AND channel_type = ?", 'LinkedIn', 'Wall'])
    wall_channel_id = wall_channel_id.id if wall_channel_id
    
    ref_key = Digest::SHA2.hexdigest(wall_channel_id.to_s + "Wall" + post_params[:job][:id].to_s + ActiveSupport::SecureRandom.base64(8))
    
    wall_post = {
      :comment => post_params[:job][:comment],
      :content => {
        :title => post_params[:job][:title],
        :description => post_params[:job][:teaser],
        :submitted_url => post_params[:job][:submitted_url] + ref_key,
        :submitted_image_url => post_params[:job][:submitted_image_url]
      },
      :visibility => {
        :code => "anyone"
      }
    }
    
    _api_wall_post = wall_post.to_xml(:root => 'share', :skip_instruct => true).to_s
    posts[:wall] = _post_linkedin(post_params[:access_token], "people/~/shares", _api_wall_post)
    
    
    # ** Prep-DB storing information
    # post_id
    post_id = ''
    # channel_id_collector = [wall_channel_id]
    
    # Status
    if posts[:wall][:response_http_object].code == '200' ||
      posts[:wall][:response_http_object].code == '201' ||
      posts[:wall][:response_http_object].code == '204'
        posts[:wall][:status_id] = 1 # For the client display
        post_status = 'Published'
    else
      posts[:wall][:status_id] = 3 # For the client display
      post_status = 'Failed'
    end
    
    posts_for_db << [
        post_params[:user_id], post_params[:job][:id], wall_channel_id, post_id, 'Wall', post_status,
        escape_single_quotes(wall_post[:comment]),
        '',
        wall_post[:content][:submitted_url],
        wall_post[:content][:submitted_image_url],
        escape_single_quotes(wall_post[:content][:title]),
        escape_single_quotes(wall_post[:content][:description]),
        ref_key,
        posts[:wall][:response_http_object].code,
        posts[:wall][:response_http_object].message.to_s,
        escape_single_quotes(posts[:wall][:response_http_object].body),
        Time.now.to_datetime.strftime("%F %T")
      ]
      
      
    {:posts => posts, :posts_for_db => posts_for_db}
    
  end
  
  def construct__auth_error_arr(callback_action, re_auth_actions)
    
    auth_url = init_linkedin_tokens(re_auth_actions, true)
    
    {
      :status => "50",
      :action => callback_action,
      :message => 'Errors were found in the fields below, please check the messages next to each field',
      :auth_url => auth_url
    }
  end
  
  def _get_linkedin(access_token, api_path)
    _api_linkedin(access_token, "get", api_path, nil)
  end
  
  def _put_linkedin(access_token, api_path, api_body)
    _api_linkedin(access_token, "put", api_path, api_body)
  end
  
  def _post_linkedin(access_token, api_path, api_body)
    _api_linkedin(access_token, "post", api_path, api_body)
  end
  
  def _api_linkedin(access_token, method, api_path, api_body)
    
    li__api_url = "http://api.linkedin.com/v1/"
    
    case method
      when "post"
        response = access_token.post( li__api_url + api_path, api_body, {'Content-Type'=>'application/xml'})
      when "put"
        response = access_token.put( li__api_url + api_path, api_body, {'Content-Type'=>'application/xml'})
      when "get"
        response = access_token.get( li__api_url + api_path)
    end
    
    
    _res = _handle_response(response)
    _res[:request_url] = li__api_url + api_path
    _res[:request_xml] = api_body
    
    _res
    
  end
  
  
  # --- This method checks the RAW LINKEDIN response information (status, exceptions etc)
  #
  # It returns either a constructed JSON object of the relevant data or a BLANK object (indicating a successful call) 
  # OR an error in the form of a Hash of ':fs_obj' and a ':auth_url' in case there was an authorization issue
  #
  def _handle_response(response)
    
    
    # -- MAJOR EXCEPTION handling (authentication)
    
    if (response == Net::HTTPUnauthorized || response.message == 'Unauthorized') ||
      (response && response['status'].to_i == 403 && response['message'] == "Access to group-memberships denied")
        raise APIAuthError.new
    
    
    # -- STANDARD handling
    
    else
      
      hashed_response = nil
      
      # Check if the 'response.body' starts with an '<?xml' tag -> indicating it's XML structure
      if response.body =~ /\A<\?xml/ 
        hashed_response = Hash.from_xml(response.body)
      else
        hashed_response = hash_a_json(response.body)
      end
      
      # -- Bad request (e.g. posting duplicate content)
      
      
      
      _res = { :response_http_object => response }
      
      
      # -- Bad request (e.g. posting duplicate content)
    
      if response == Net::HTTPBadRequest || response.message == "Bad Request" || response.code == 400
        _res[:status] = "bad_request"
        _res[:response_object] = hashed_response
      
      
      # -- API SERVICE ERROR
      
      elsif response == Net::HTTPInternalServerError || response.message == 'Internal Server Error' || response.code == 500
        _res[:status] = "api_service_error"
        _res[:response_object] = hashed_response
        
      
      # -- FORBIDDEN -> trying to use a resource the user is not allowed, store the 'body' as plain XML at this point
        
      elsif response == Net::HTTPForbidden || response.message == 'Forbidden'
        _res[:status] = "denied_access"  # e.g. post to LinkedIn group required moderation by an admin
        _res[:response_object] = hashed_response
        
        # Check if additional permissions are required (SHARING)
        if _res[:response_object]['error']['message'] == 'Access to posting shares denied'
          raise APIAuthError.new
        end
      
      
      # -- POST / PUT
      
      elsif response.body.blank? || (response.body.nil? && response.code == 204)   # A response without content -> successful  
        _res[:status] = "updated_successfully"
        
        if response.body.blank?
          _res[:response_object] = {}
        else
          _res[:response_object] = hashed_response
        end
      
        
      # -- GET
      
      else
        _res[:status] = "retrieved_successfully"
        _res[:response_object] = hashed_response
        
      end
      
    end
    
    
    _res
    
  end  
  
  
  def li__post_to_single_group(access_keys)
    
    # ------ 1 - Get the consumer
          
    access_token = OAuth::AccessToken.new(get_linkedin_consumer(3), access_keys[:access_token], access_keys[:access_secret])
    
    
    # ------ 2 - Create the post
    
    # * Hardcoding the job_id
    b = request.env["HTTP_HOST"]
    if b == 'localhost:3000' # local
      # job = Fs2Job.find_by_id(164)
      job = Fs2Job.find_by_id(100)
    else # remote
      job = Fs2Job.find_by_id(100)
    end
    
    # * Temporarily disabling reading the 'job_id' from the 'session' object
    # job = Fs2Job.find_by_id(session[:jobs][:active_job_id].to_i)
    
    a = {
        # :title => "'Leading Client Developer' @ Wix [Tel Aviv]",
        :title => "Front-end developer (Wix)",
        :summary => "Wix is looking for a brilliant, experienced client developer for a leading position in a cutting edge web & mobile development team and in a challenging and creative environment.",
        :content => {
           :submitted_url => "http://5skills.me/job_post/#{job.id}",
           :submitted_image_url => "http://5skills.me/5_only-141x160.png",
           :title => "APPLY NOW",
           :description => "Apply with your skills. Not your CV."
          }
        }.to_xml(:root => 'post', :skip_instruct => true).to_s
        
        
    # -------- HEBREW TEST -----------
    a = {
        # :title => "'Leading Client Developer' @ Wix [Tel Aviv]",
        :title => "מפתח צד לקוח לחברת סטארט-אפ",
        :summary => "JQuery, Javascript, CSS3.0, Javascript, Ruby on Rails, HTML",
        :content => {
           :submitted_url => "http://5skills.me/job_post/#{job.id}",
           :submitted_image_url => "http://5skills.me/5_only-141x160.png",
           :title => "לחץ כאן להגשת מועמדות!",
           :description => "הגשת מועמדות באמצעות הכישורים שלך וללא קורות חיים. נסו עכשיו."
          }
        }.to_xml(:root => 'post', :skip_instruct => true).to_s
        
    response = access_token.post("http://api.linkedin.com/v1/groups/#{params[:group_id]}/posts", a, {'Content-Type'=>'application/xml'})
    
    
    # user_posts = access_token.get("http://api.linkedin.com/v1/people/~/group-memberships/#{params[:group_id]}/posts:(creator:(first-name,last-name,picture-url),title,summary,creation-timestamp,likes,comments,attachment:(image-url,content-domain,content-url,title,summary))?format=json&role=creator&category=discussion")
    
    # ------ 3 - Identify if the discussion post has to be moderated
    #   Currently, if there is no 'response['location']' attribute in the response object, it is assumed the post must be moderated
    
    if response['location']
      
    end
    
    # ------ 3 - Flag the post as a job discussion ('put')
    
    post_id = response['location'].split("/").last
    b = "<code>job</code>"
    
    response_post_type = access_token.put("http://api.linkedin.com/v1/posts/#{post_id}/category/code", b, {'Content-Type'=>'application/xml'})
    
    response
    
  end

  # ------------------------------------------
  #             TEST
  # ------------------------------------------
  
  def do_linkedin_by_person_id(person_id, access_keys = {:access_token => session[:access_token], :access_secret => session[:access_secret]})
    return nil if access_keys[:access_token].nil? || access_keys[:access_secret].nil?
    
    access_token = OAuth::AccessToken.new(get_linkedin_consumer(2), access_keys[:access_token], access_keys[:access_secret])
    response = access_token.get("http://api.linkedin.com/v1/people/id=#{person_id}:(id,first-name,last-name,email-address,headline,location:(name,country:(code)),industry,skills,positions,educations,connections)")
    # response = access_token.get("http://api.linkedin.com/v1/people/id=#{person_id}:(id,first-name,last-name,email-address,skills)?format=json")  
    
    return nil if response == Net::HTTPUnauthorized || response.message == 'Unauthorized'
    
    # hash_a_json(response.body)
  end  
  
  
  #
  # Social providers
  # - 1 = LinkedIn
  # - 2 = Twitter
  # - 3 = Facebook
  #
  # Permission type (array of integers)
  # - 9 - Groups
  #
  def do_linkedin_login_2(provider_permissions = {:provider => 1, :permissions => 1})
    
    puts "---- get_provider_request_token"
    
    case provider_permissions[:permissions]
          
      when 1 # ----- add groups
        configuration = { :site => 'https://api.linkedin.com',
          :authorize_path => '/uas/oauth/authorize',
          :request_token_path => '/uas/oauth/requestToken?scope=r_fullprofile+r_emailaddress+r_network+r_contactinfo+rw_groups',
          :access_token_path => '/uas/oauth/accessToken' }
    end
     
    consumer = OAuth::Consumer.new(LINKEDIN_API_KEY, LINKEDIN_API_SECRET, configuration)
    
    session[:request_token] = consumer.get_request_token({:oauth_callback => linkedin_auth_accept_url + "?rk=1"})
    redirect_to session[:request_token].authorize_url
    
  end  
  
  # ------------------------------------------
  #             TEST
  # ------------------------------------------
  
  
  
    
  #
  # ERROR CODES:
  # -------------
  #
  #  100 - Fields not valid (in a form)
  #  101 - User can't be authenticated (either email or password incorrect)
  # 
  def login_from_hash(h_login_params, is_login = true)
    @response_message = 'Logged in successfully.'
    @is_success = true
    @error_code = 100 # Fields not valid    
    @user_login = Fs2UserLogin.new({:email => h_login_params[:email], :password => h_login_params[:password]})
    
    ## Check if login attributes are valid (before doing a full database check)
    if @user_login.valid?
      
      ## Authenticate and store user object in session
      if session[:user] = Fs2User.authenticate(h_login_params)
        
        init_person_objects
        
        ## Check if 'save_login' has been checked (for auto-login)        
        init_cookie_login_from_session if h_login_params[:save_login]

      else
  
        @error_code = 101
        @response_message = 'Either Email or Password are incorrect.'
        @is_success = false
        
      end
    else
      @response_message = "Errors found in fields!!"
      @is_success = false
    end
    
    if @person.nil? && session[:user]
      @response_message = "'User' object not associated to any 'Person' object. Make sure the 'UserID:" + session[:user].id.to_s + "' is associated with a 'person' object!"
      @is_success = false
    end
    
    if @is_success
      flash[:notice_hold] = @response_message
      
      if h_login_params[:redirect_to].nil? && session[:return_to]
        
        redirect_to session[:return_to]
        
      elsif h_login_params[:redirect_to]
        
        redirect_to :action => h_login_params[:redirect_to][:action], :controller => h_login_params[:redirect_to][:controller]
        
      elsif session[:user].user_type_id == Fs2User::USER_TYPES[:recruitment_agent] || session[:user].user_type_id == Fs2User::USER_TYPES[:hiring_manager]
        
        redirect_to :action => :create_job_profile, :controller => :five_skills if !is_login || session[:job].nil?
        
        # redirect_to :action => :find_job_seekers, :controller => :five_skills if is_login && session[:job]
        redirect_to :action => :edit_job_profile, :controller => :fs_job, :job_id => session[:job].id if is_login && session[:job]
        
      elsif session[:user].user_type_id == Fs2User::USER_TYPES[:job_seeker]
        
        redirect_to :action => :create_job_seeker_profile, :controller => :five_skills if !is_login
        
        # redirect_to :action => :find_jobs, :controller => :five_skills if is_login
        redirect_to :action => :edit_job_seeker_profile, :controller => :fs_job_seeker, :job_seeker_id => session[:person].id if is_login
        
      end

    else
      flash[:error] = @response_message
      
      respond_to do |format|
        format.html { render '/five_skills/home_logged_out.html', :layout => "five_skills_homepage" }
      end
    end
  end
  
  def process_forgot_password
    if params[:login]['email'].empty?
      flash[:error] = "Please enter an email address."
      render 'forgot_password.html', :layout => "homepage"
    else
      @person = Person.find_by_primary_email(params[:login]['email'])
    
      if @person
        redirect_to :action => 'email_forgot_password', :controller => :messages, :person_id => @person.id
      else
        flash[:error] = "Couldn't find the email in the database, make sure you entered the right email address or perhaps you need to register."
        redirect_to :action => 'login', :username => params[:login]['email']
      end
    end      
  end
  
  def forgot_password
    render 'forgot_password.html', :layout => "homepage"
  end
  
  def forgot_password_email_sent
    render 'forgot_password_email_sent.html', :layout => "homepage"
  end
  
  def email_confirm_sent
    render 'email_confim_sent.html', :layout => "homepage"
  end
  
  def init_cookie_login_from_session
    session[:user].remember_me
    cookies[:auth_token] = { :value => session[:user].remember_token , :expires => session[:user].remember_token_expires }
  end

  def do_logout
    
    reset_session
    
    session[:user].forget_me if session[:user]
    session[:user] = nil
    cookies.delete :auth_token
    
    @user_type_id = Fs2User::USER_TYPES[:job_seeker]
    
    # add_field_binder("search_company-name", "search_company-id", 
      # "view_company_summary", FIELD_COLLECTION_TYPES[:companies],
      # {:include_image => true})
    # add_field_binder("search_agency-name", "search_agency-id", 
      # "view_agency_summary", FIELD_COLLECTION_TYPES[:agencies],
      # {:include_image => true})

    flash[:notice_hold] = 'Logged out successfully.'
    
    # render '/five_skills/home_logged_out.html', :layout => 'five_skills_homepage'
    redirect_to :action => :home, :controller => :five_skills
    
  end
end
  