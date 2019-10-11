require "addressable/uri"
require 'open-uri'
require 'nokogiri'
#require 'imgkit'

class BookmarkletController < ApplicationController

  skip_before_filter :verify_authenticity_token
  skip_before_filter :login_required
  
  before_filter :check_token, :except => 
    [:bl_check_session,
    :bl_notify_login,
    :bl_login, 
    :bl_process_login,
    
    :bl_social_login,
    :bl_facebook_post,
    :bl_prepare_post]
    
  before_filter :convert_json_to_hash
  
#  before_filter :check_url_source
#  before_filter :validate_dynamic_form
#  before_filter :combine_split_requests
#  before_filter :validate_dynamic_form, :unless => :split_requests_not_complete?
  
#  def split_requests_not_complete?
#    return false if !session[:split_requests_complete]
#    
#    return true
#  end

#  def bl_ping
#    render :json => "{authenticity_token:'" + form_authenticity_token.to_s + "'}", :callback => params[:callback]
#  end

  def convert_json_to_hash
    return if !params[:json] || params[:json] == "null"
    
    params.merge!(ActiveSupport::JSON.decode(params[:json]))
    params.delete('json') 
  end
  
  # This method will create the ajax session token in case it doesn't exist already
  #
  def check_token
    
#    puts "+++++++++++++ header: " + request.env["HTTP_BOOKMARKLET_SESSION_TOKEN"].to_s
    
    begin
      
      @key = request.env["HTTP_BOOKMARKLET_SESSION_TOKEN"]
      @key = params[:key] if !@key
      
      if !@key 
        raise "ERROR: Bookmarklet session TOKEN not available !!!"
      elsif !session[:user]
        @person = Person.find_by_bookmarklet_session_token(@key)
        
        raise "ERROR: Invalid Bookmarklet session TOKEN !!!" if !@person
        
        session[:user] = @person
      end
      
    rescue Exception => exc
      
      # Ensure the user is redirected to the login-screen
      @arr = {
        :status => "001",
        :action => "check_token",
        :message => exc.message
      }
      
      print exc.message
      
      respond_to do |format|
        format.json { render :json => @arr.to_json, :callback => params[:callback] }
      end
      
    end
    
#    if !session[:flyc_token]
#      session[:flyc_token] = Digest::MD5.hexdigest(session[:url_source].to_s + Time.now.to_s)
#    elsif !session[:bl_first_time] && session[:user] && !params[:flyc_token] 
#      session[:bl_first_time] = 1
#    elsif session[:bl_first_time] && (!params[:flyc_token] || params[:flyc_token] != session[:flyc_token])
#      raise "ERROR: Invalid Flyc Token!"
#    end
#       
#    session[:bl_first_time] = nil if session[:bl_first_time].to_i == 1

  end
  
#  def check_url_source
    
#    return if session[:url_source] && params[:action] != "bl_bookmark_site"
#    
#     begin
#      
#      raise 'ERROR: URL was not passed as paramter to bookmarklet controller!' if !params[:url]
#      session[:url_source] = Addressable::URI.parse(params[:url])
#      
#    rescue Exception => exc
#      print exc.message
#    end

#  end
  
  def access_denied
    flash.clear
    flash[:error] = 'Oops. You need to login before you can view that page.'
    
    params[:bl_return_to_action] = params[:action]
    @state = 1
    
    # Set the token
#    check_url_source
#    check_token
    
    redirect_to :controller => 'bookmarklet', :action => 'bl_login'
  end
  
  def bl_process_login
    
    process_login
    
    # If success, redirect to last requested url
    
    if @is_success
        
        generate_bookmarklet_session_token(session[:user])

        @arr = {
          :status => 200,
          :action => "process_login",
          :key => session[:user].bookmarklet_session_token,
          :remember_me_flag => params[:save_login][:checked],
          :message_panel_name => "primary_messages",
          :message_panel_message => @response_message
        }
        
        # In case the user is an 'admin', add an 'admin flag'
        # **TODO: I must implement additional security measures to ensure only certain people can login
        #         as admins and perfor system changes
        if session[:user].person_type_id == 0 # User is 'admin'
          @arr[:is_admin] = true
        end
      
    else
      
      @state = 0
      @errors = {}
        
      if @person_login && @person_login.errors
        @person_login.errors.each do |attr, msg|
          @errors[attr] = msg
        end
      end
      
      # json structure
      @arr = {
          :status => @error_code,
          :action => "process_login",
          :message_panel_name => "login_messages",
          :message_panel_message => @response_message,
          :errors => @errors
        }
  
    end

    respond_to do |format|
#      format.js {render '/bookmarklet/login.js', :layout => false}
      format.json {render :json => @arr.to_json, :callback => params[:callback]}
    end 
    
  end
  
  def bl_logout
    
#    @tmp_session = session[:url_source]
    
#    logout
    
#    session[:url_source] = @tmp_session
#    flash[:notice_hold] = 'Logged out successfully.'

    @state = 1  
    
    @arr = {
          :status => 200,
          :action => "logout",
          :key => session[:user].bookmarklet_session_token,
          :logged_in_details_html => "",
          :message_panel_name => "primary_messages",
          :message_panel_message => @response_message
        }
    
    respond_to do |format|
      format.json {render :json => @arr.to_json, :callback => params[:callback]}
    end

  end

  def bl_prepare_post
    @kit = PDFKit.new("http://www.google.com")

    @photo = Photo.new
    @photo.binary_data = @kit.to_pdf
    @photo.save!

#    format.jpg do
#      send_data(@kit.to_jpg, :type => "image/jpeg", :disposition => 'inline')
#    end

    # json structure
    @arr = {
        :status => "200",
        :action => "prepare_post"
      }

    respond_to do |format|
      format.json {render :json => @arr.to_json, :callback => params[:callback]}
    end
  end

  def bl_social_post
    
    if params[:social][:provider] == "facebook"

      url = URI.parse( "https://graph.facebook.com/me/feed?" + 
        "app_id=" + "156127131075698" + "&" + 
        "message=" + URI::escape(params[:post][:message]) + "&" +
        "picture=" + URI::escape(params[:post][:picture]) + "&" + 
        "link=" + URI::escape(params[:url]) + "&" + 
        "name=" + URI::escape(params[:post][:name]) + "&" + 
        "caption=" + URI::escape(params[:post][:caption]) + "&" + 
        "description=" + URI::escape(params[:post][:description]) + "&" +  
        "redirect_uri=" + "http://localhost:3002/" + "&" + 
        "access_token=" + params[:social][:access_token])
    
      http = Net::HTTP.new( url.host, url.port )
      http.use_ssl = true if url.port == 443
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE if url.port == 443
  #   path = url.path + "?" + url.query
  
      puts " YYYYYYYYYY: " + url.path + " ; " + url.query
    
      data = http.post( url.path, url.query )
        
      puts " XXXXXXXXXXXX data: " + data.body.to_json
      
    end
    
    # json structure
    @arr = {
        :status => "200",
        :action => "social_post",
        :social_provider_response => data.body.to_json
      }

    respond_to do |format|
      format.json {render :json => @arr.to_json, :callback => params[:callback]}
    end
    
  end
  
  def bl_notify_logout
    
#    @tmp_session = session[:url_source]
    
    logout
    
#    session[:url_source] = @tmp_session
#    flash[:notice_hold] = 'Logged out successfully.'

    @state = 1
    @bookmarklet_token = params[:key]
    @server_response = "code:200"
    
    render 'bookmarklet/simple.html', :layout => false
    
  end
  
  def bl_login
    @state = 1
    
    # json structure
    @arr = {
        :status => "200",
        :action => "login",
        :primary_messages_html => render_to_string(:partial => '/bookmarklet/primary_messages_panel.html'),
        :content_html => render_to_string("/bookmarklet/login.html"),
        :buttons_html => render_to_string(:partial => '/bookmarklet/buttons_panel.html')
      }

    respond_to do |format|
      format.js {render '/bookmarklet/login.js', :layout => false}
      format.json {render :json => @arr.to_json, :callback => params[:callback]}
    end
    
  end
  
  #
  # This method will validate a particular dynamic form based on the 'previous' action used
  #
  def validate_dynamic_form
    
    failed_validation = false
    redirect_to_page = ""
    @activities_h = Activity::activities 
    
    if session[:last_activity_o]
      puts "TEST" + session[:last_activity_o].action + " ; " + params[:action] + " || " + 
        @activities_h[params[:action]].to_s + " ; " + @activities_h[params[:action]][3].to_s
    end
    
    # If current action is dynamic, check the last action
    if (@activities_h[params[:action]] && @activities_h[params[:action]][3] == 2)
      
      if session[:last_activity_o] && 
          (session[:last_activity_o].action == "bl_job_ad" && session[:last_activity_o].controller == "bookmarklet")
      
        puts "Inside"
      
        @role = Role.new(params[:role])
        @role.external_link = session[:url_source].to_s

        @role_application = RoleApplication.new(params[:role_application])
        @role_application.role = @role
        @role_application.person = session[:user]    
          
        ## ROLE and ROLE_APPLICATION
        failed_validation = true if !@role_application.valid?
        failed_validation = true if !@role.valid?
#        raise 'ERRORS: ' + @role.errors.to_xml if failed_validation
#        raise 'ERRORS: ' + @role_application.errors.to_xml if failed_validation
#        
#        flash[:error] = exc.message

        redirect_to_page = "bookmark_site.js"
        
      end
      
    end
    
    if failed_validation
      @state = 0
      
      respond_to do |format|
        format.js {render '/bookmarklet/' + redirect_to_page, :layout => false}
      end
    end
  end
  
  def combine_split_requests
    return if !params["split"]
    
    @split_a = params["split"].split("-")
    
#    session[:splits] = nil
#      session[:splits_counter] = nil
    
    puts "   SPLIT: " + @split_a[0] + " ; " + request.query_parameters.to_s
    
    # Store the split in session
    session[:splits] = Hash.new if !session[:splits]
    session[:splits_counter] = Hash.new if !session[:splits_counter]
    
    session[:splits].merge!(request.query_parameters)
    session[:splits_counter] = session[:splits_counter].merge!({params["split"] => true})
    
    # check if this is the last split
    # If it is, construct the complete params hash and continue to the appropriate action
    # *** Add check to make sure all transmissions have gone through
    puts "  COUNT: " + session[:splits_counter].to_s
    
    if session[:splits_counter] && session[:splits_counter].size == @split_a[1].to_i
      
      session[:splits].each do |value|
        puts " XXX : " + value.to_s
      end

      params.merge!(session[:splits])
      
      puts "PARAMS: " + params.to_s
      
      session[:splits] = nil
      session[:splits_counter] = nil
      
      session[:split_requests_complete] = true
      
      return
      
    end
    
#    session[:splits] = nil
#      session[:splits_counter] = nil
    
    render :nothing => true, :status => :ok
  end
  
  def bl_job_ad
    @state = 6
    
    respond_to do |format|
      format.js {render '/bookmarklet/bookmark_site.js', :layout => false}
    end
  end
  
  def bl_actions
    @state = 5
    

    
    respond_to do |format|
      format.js {render '/bookmarklet/bookmark_site.js', :layout => false}
    end
  end
  
  def bl_json_test
#    @html_doc = Nokogiri::HTML(open(session[:url_source].to_s))
#    @parsed_page_h = Hash.new
#    @itr = 0
#    
#    puts 'BEFORE'
#    @html_doc.css("html > body > center").each do |node|
#      puts 'DURING'
#      puts node.text
#      
#      @parsed_page_h[@itr] = node.text 
#      @itr = @itr + 1
#    end
    
#    print "SS: " + @job_titles_o.to_s    
#    render :json => "{id:1, roleName:'" + @job_titles_o.first.text + "'}", :callback => params[:callback]  

    render :json => "{id:1, roleName:'" + session[:user].first_name + "'}", :callback => params[:callback]
  end
  
  #
  # *************************** SESSION-BASED external calls ***************************
  # This method is the method used to check the session state of the user on the 'host site'
  # This method will have access to the local 'host-based' session information
  #
  # All other bookmarklet actions will be transient as they are called from the various websites on the web.
  # By using the 'easyXDM' Javascript library, the client can have access to the 'host site'
  # *************************** SESSION-BASED external call ***************************
  #
  def bl_check_session
    
    # Check if the user is logged in (has an active session)
    # If not, check if he's got a cookie (to perform the auto-login)
    # Otherwise, return user not logged-in -> requires the user to login using the bookmarklet or redirect to the site

    # 1. Auto-login user based on a valid and active bookmarklet token -->
    #               Previously logged in using the bookmarklet
    #  * User has a 'bookmarklet_session_token' attribute defined
    #  * User has a valid session OR cookie on the 'host site'
    #
    # 2. Auto-login user based on the 'host site' credentials --> 
    #               hasn't used bookmarklet yet, but logged in with a vaild session OR cookie
    #  - User doesn't have a valid 'bookmarklet_session_token'
    #  - If the user has an active session (checking session[:user])
    #  - OR if the user has a valid cookie (for 'remember me' functionality)
    # 
    # 3. User is required to login -->
    #               hasn't used the 'host site', not logged in using the bookmarklet before
    #               OR session OR cookie has expired on the 'hots site'
    #  - User logged out from the 'host site'
    #  - User has an inactive session without a cookie or with an invalid cookie

    # Otherwise, check if the user has an active cookie
    login_from_cookie if session[:user].nil? && cookies[:auth_token]
    
    if session[:user] # User logged in through the host site
      
      @server_response = "key:"
      
      if !(@server_response = @server_response + session[:user].bookmarklet_session_token)
        
        # Create the 'bookmarklet_session_token' for subsequent bookmarklet calls
        @server_response = @server_response + generate_bookmarklet_session_token(session[:user])
      
      end
      
    else # User might have used the bookmarklet before but session or cookie expired --> force login and ensure bookmarklet token is reset
      @server_response = "err:000"
    end
    
    @flyc_action = "login"
    
    render 'bookmarklet/simple.html', :layout => false
    
  end
  
  def generate_bookmarklet_session_token(person_o)
    @bookmarklet_token = Digest::SHA1.hexdigest("#{person_o.primary_email}--#{1.minute.from_now}")
    person_o.update_attribute(:bookmarklet_session_token, @bookmarklet_token)
    
    @bookmarklet_token
  end
  
  def bl_admin_save_page
#    session[:user] = Person.find_by_bookmarklet_session_token(params[:key])

    begin
      
      failed_validation = false
      @errors = {}
      @response_message = ""
      @organisation = nil
      @parsing_page = nil
    
      # ----------------- Organisation -----------------
      # New organisations
      if !params[:site_organisation_id] || params[:site_organisation_id].blank? 
        @organisation = Organisation.new
        @organisation.status_id = 1
        @organisation.type_id = params[:site_organisation_type_id]
        @organisation.website = params[:site_url].strip if params[:site_url]
        @organisation.name = params[:site_name].strip if params[:site_name]
        failed_validation = true if !@organisation.valid?
        
        if @organisation && @organisation.errors
          @organisation.errors.each do |attr, msg|
            @errors[attr] = msg
          end
        end
        
        if !failed_validation
          @organisation.save(false)
          @response_message = "Successfully saved new website."
        end
        
      # Update existing organisation
      else
        @organisation = Organisation.find_by_id(params[:site_organisation_id])
        @organisation.update_attributes!({
          :name => params[:site_name],
          :type_id => params[:site_organisation_type_id]})
          
        @response_message = "Successfully updated website."
      end
      # ----------------- Organisation -----------------
      

      # ----------------- Page -----------------
      # New page (for an existing organisation)
#      if !params[:site_page_id] || params[:site_page_id].blank?
      if params[:page_type_path_selection] && 
          (params[:page_type_path_selection].to_i == -2 || # 'New' selected 
          params[:page_type_path_selection].to_i == -1) # New 'Blank' selected
        @parsing_page = WebsiteParsingPage.new
        @parsing_page.organisation_id = @organisation.id if @organisation
        @parsing_page.uri_string = params[:page_type_path].strip if params[:page_type_path]
        @parsing_page.uri_string = "{blank}" if params[:page_type_path_selection].to_i == -1
        @parsing_page.page_type = params[:page_type]
        failed_validation = true if !@parsing_page.valid?
        
        if @parsing_page && @parsing_page.errors
          @parsing_page.errors.each do |attr, msg|
            @errors[attr] = msg
          end
        end
        
        if !failed_validation
          @parsing_page.save(false)
          @response_message = @response_message + "<br/>Successfully saved new page."  
        end
        
      # Update existing page
      else
        @parsing_page = WebsiteParsingPage.find_by_id(params[:page_type_path_selection])
        @parsing_page.update_attributes!({:uri_string => params[:page_type_path], :page_type => params[:page_type]})
        
        @response_message = @response_message + "<br/>Successfully updated page."
      end
      # ----------------- Page -----------------
      
      raise 'ERROR' if failed_validation
      
      # SUCCESS json object
      @arr = {
          :status => "200",
          :action => "admin-save_page",
          :is_admin => true,
          :is_blank_uri_string => params[:page_type_path_selection].to_i == -1,
          :is_new_uri_string => params[:page_type_path_selection].to_i == -2,
          :message_panel_name => "primary_messages",
          :message_panel_message => @response_message
        }
        
      @arr[:organisation_id] = @organisation.id if @organisation
      @arr[:page_id] = @parsing_page.id if @parsing_page
      
    rescue Exception => exc
      
      @response_message = @response_message + "<br/>" if !@response_message.blank? 
      @response_message = @response_message + "Errors found in fields!!"
      puts "*** Unhandled Exception: " + exc.message
      
      # json structure
      @arr = {
          :status => 100,
          :action => "admin-save_page",
          :message_panel_name => "primary_messages",
          :message_panel_message => @response_message,
          :is_admin => true,
          :errors => @errors
        }
      
    end

    respond_to do |format|
      format.json {render :json => @arr.to_json, :callback => params[:callback]}
    end
  end
  
  def bl_admin_save_field
#    session[:user] = Person.find_by_bookmarklet_session_token(params[:key])

    begin
      
      failed_validation = false
      @errors = {}
      @response_message = ""
      @organisation = nil
      @parsing_page = nil
    
      # ----------------- Field -----------------
      # New field
      if !params[:field_type] || params[:field_type].to_i < 0
        @parsing_field = WebsiteParsingField.new
        @parsing_field.website_parsing_page_id = params[:site_page_id]
        @parsing_field.jquery_css_selector = params[:jquery_css_selector]
        @parsing_field.field_type = params[:field_type]
        failed_validation = true if !@parsing_field.valid?
        
        if @parsing_field && @parsing_field.errors
          @parsing_field.errors.each do |attr, msg|
            @errors[attr] = msg
          end
        end
        
        if !failed_validation
          @parsing_field.save(false)
          @response_message = "Successfully saved new 'Field'."
        end
        
      # Update existing organisation
      else
        @parsing_field = WebsiteParsingField.find_by_id(params[:field_type])
        @parsing_field.update_attributes!({
          :jquery_css_selector => params[:jquery_css_selector]})
          
        @response_message = "Successfully updated 'Field'."
      end
      # ----------------- Field -----------------
      
      raise 'ERROR' if failed_validation
      
      # SUCCESS json object
      @arr = {
          :status => "200",
          :action => "admin-save_field",
          :is_admin => true,
          :field_id => @parsing_field.id,
          :message_panel_name => "primary_messages",
          :message_panel_message => @response_message
        }
      
    rescue Exception => exc
      
      @response_message = @response_message + "<br/>" if !@response_message.blank? 
      @response_message = @response_message + "Errors found in fields!!"
      puts "*** Unhandled Exception: " + exc.message
      
      # json structure
      @arr = {
          :status => 100,
          :action => "admin-save_field",
          :message_panel_name => "primary_messages",
          :message_panel_message => @response_message,
          :is_admin => true,
          :errors => @errors
        }
      
    end

    respond_to do |format|
      format.json {render :json => @arr.to_json, :callback => params[:callback]}
    end
  end
  
  def bl_admin_get_site_and_page_details
    # Store 'session_flyc_token' in database with IP as unique identifier
    # as using Post from cross-domain, the session is somehow lost.
    # Checking 'session' against the IP will ensure there is some consistency with this
#    puts "XXXX: "+ session[:user].first_name if session[:user]
    
    @state = 1
    @page_type_options_arr = WebsiteParsingPage.page_types
    @organisation = Organisation.find_by_id(params[:site_organisation_id])
    @url_path = params[:url_path]
    
    @is_site_detected = false
    @site_detected = "Unknown"
    @site_detected = "Unable to detect source URL" if !@url_o
    @page_detected = 0
    @website_fields = Array.new
    
    # Flag the type of page found based a match between the '@url_o' and the '@sites' page attributes  
    @site_detected = @organisation.name if @organisation && @organisation.name
    
    @is_site_detected = true if @site_detected
    
    if @organisation
      @site_organisation_type = @organisation.type_id
      
      # Query will select all pages where the 'blank' page (if exists) will appear last
      @website_pages_db = WebsiteParsingPage.find(
        :all, 
        :conditions => [ "organisation_id = ?", @organisation.id],
        :select => 'id, uri_string, page_type')
    end 
      
    @state = 4
    @page = nil
    @website_field_db = nil
    @page_type = 1 # Default = 'Search results'
    @jquery_css_selector = nil
    @site_organisation_type = 3 # Default = 'job board'
    @page_type_path = ""
    @page_type_path_arr = [["-- New --", -2], 
      ["- Blank -", -1]]
    @is_blank_page_selected = false
    @inner_page = 1
    @page_id = nil
    
    if @website_pages_db
      @website_pages_db.each do |page|
        if page.uri_string && !page.uri_string.blank? && !(page.uri_string == "{blank}")
          @page_type_path_arr[@page_type_path_arr.length] = [page.uri_string, page.id]
        else
          @is_blank_page_selected = true
          @page_type_path_arr[1][1] = page.id
        end
        
        if !@page && (@is_blank_page_selected || @url_path.match(page.uri_string))
          @page = page
          @page_id = page.id
          @page_type = page.page_type
          @page_type_path = page.uri_string
            
#            break
        end 
      end
    end
    
    @arr = {
        :status => "200",
        :action => "admin-get_site_and_page_panel",
        :page_id => @page_id,
        :page_type => @page_type,
        :organisation_type_id => @site_organisation_type,
        :panel_html => render_to_string(:partial => '/bookmarklet/admin/site_and_page_details.html'),
        :widget_tabs_html => render_to_string(:partial => '/bookmarklet/admin/widget_tabs.html'),
        :is_admin => true
      }

    respond_to do |format|
      format.json {render :json => @arr.to_json, :callback => params[:callback]}
    end 
  end
  
  def bl_admin_get_field_details
    @jquery_css_selector = nil
    
    if params[:field_type] && params[:field_type].to_i > 0
      @website_field = WebsiteParsingField.find_by_id(params[:field_type])
      @jquery_css_selector = @website_field.jquery_css_selector if @website_field
    end 
    
    # json structure
    @arr = {
        :status => "200",
        :action => "admin-get_field_details",
        :jquery_css_selector => @jquery_css_selector,
        :is_admin => true
      }

    respond_to do |format|
      format.json {render :json => @arr.to_json, :callback => params[:callback]}
    end
  end
  
  def bl_admin_get_page_fields_details
    @inner_page = 2
    @field_type = -1 # Default = 'Job title'
    @field_type = params[:field_type] if params[:field_type]
    @jquery_css_selector = nil
    @field_type_options_arr = WebsiteParsingField.field_types
    
    @website_fields = WebsiteParsingField.find(
      :all,   
      :conditions => [ "website_parsing_page_id = ?", params[:site_page_id].to_i])
    
    if @website_fields
      @website_fields.each do |field|
        @field_type_options_arr.rassoc(field.field_type)[1] = field.id
        @jquery_css_selector = field.jquery_css_selector if field.field_type == -1
      end
    end
    
    # json structure
    @arr = {
        :status => "200",
        :action => "admin-get_fields_details_panel",
        :jquery_css_selector => @jquery_css_selector,
        :panel_html => render_to_string(:partial => '/bookmarklet/admin/fields_details.html'),
        :widget_tabs_html => render_to_string(:partial => '/bookmarklet/admin/widget_tabs.html'),
        :is_admin => true
      }

    respond_to do |format|
      format.json {render :json => @arr.to_json, :callback => params[:callback]}
    end
  end
  
  def bl_social_login
    
    render 'bookmarklet/simple.html', :layout => false
    
  end
  
  def bl_admin_bookmark_site
    # Store 'session_flyc_token' in database with IP as unique identifier
    # as using Post from cross-domain, the session is somehow lost.
    # Checking 'session' against the IP will ensure there is some consistency with this
#    puts "XXXX: "+ session[:user].first_name if session[:user]
    
    @state = 4
    @url_o = Addressable::URI.parse(params[:url])
    @organisations = Organisation.find(
      :all, 
      :conditions => [ "website like ?", "%" + @url_o.host])
      
    @organisation = @organisations[0] if @organisations
    
    @is_new_site = true if !@organisation
    
    @arr = {
        :status => "200",
        :action => "admin-bookmark",
        :url_path => @url_o.path,
        :logged_in_details_html => render_to_string(:partial => '/bookmarklet/logged_in_panel.html'),
        :primary_messages_html => render_to_string(:partial => '/bookmarklet/admin/primary_messages_panel.html'),
        :content_html => render_to_string("/bookmarklet/admin/bookmark_site.html"),
        :buttons_html => render_to_string(:partial => '/bookmarklet/buttons_panel.html'),
        :is_admin => true
      }
      
    @arr[:organisation_id] = @organisation.id if @organisation

    respond_to do |format|
      format.json {render :json => @arr.to_json, :callback => params[:callback]}
    end    
  end
  
  def bl_save_job
    # Create the 'Role'
    @role = Role.new
    @role.title = params[:jobs][:job1]["-1"]
    @role.description = params[:jobs][:job1]["-2"]
    @role_id = params[:jobs][:job1]["role_id"]
    @errors = {}
    
    begin
      if @role && !@role.valid? && @role.errors
        @role.errors.each do |attr, msg|
          @errors[attr] = msg
        end
        
        raise "ERRORS..."
      end

      Role.transaction do
        if @role_id.to_i < 0        
          @role.save(false)
          @role_id = @role.id
        elsif @role_id.to_i > 0
          Role.update(@role_id.to_i, {
            :title => @role.title,
            :description => @role.description})
        end  
      end
      
      @arr = {
          :status => "200",
          :action => "save_job",
          :role_id => @role_id,
          :message_panel_name => "primary_messages",
          :message_panel_message => "Successfully saved one job!"
        }
        
      @arr[:organisation_id] = @organisation.id if @organisation
      
    rescue Exception => exc
      puts "ERROR: " + exc.message
      
      # json structure
      @arr = {
          :status => 100,
          :action => "save_job",
          :message_panel_name => "primary_messages",
          :message_panel_message => "Failed to save job, check fields below!",
          :errors => @errors
        }
    end

    respond_to do |format|
      format.json {render :json => @arr.to_json, :callback => params[:callback]}
    end      
  end
  
  def bl_save_jobs
    @jobs_to_insert_h = Hash.new
    
    # Create the jobs
    # 1. Create roles
    params[:jobs].each do |job_k, job_v|
      @jobs_to_insert_h[params[:jobs][job_k]["role_id"]] = Role.new
      @jobs_to_insert_h[params[:jobs][job_k]["role_id"]].title = params[:jobs][job_k]["-1"]
      @jobs_to_insert_h[params[:jobs][job_k]["role_id"]].description = params[:jobs][job_k]["-2"]
    end
    
    begin
      # 2. Check if all roles are valid
      @jobs_to_insert_h.each do |role_k, role_v|
        raise "ERRORS... " if !role_v.valid?
      end
      
      #save parents and their children in one transaction
      Role.transaction do
        
        # Iterate through all jobs and 'save' them to the database
        @jobs_to_insert_h.each do |role_k, role_v|
        
          if role_k.to_i < 0        
            role_v.save(false)
            @jobs_to_insert_h[role_k] = role_v.id
          elsif role_k.to_i > 0
            Role.update(role_k.to_i, {
              :title => role_v.title,
              :description => role_v.description})
            @jobs_to_insert_h[role_k] = role_k.to_i
          end
        end
        
      end
    rescue Exception => exc
      puts "ERROR: " + exc.message    
    end
    
    @arr = {
        :status => "200",
        :action => "save_jobs",
        :role_ids => @jobs_to_insert_h,
        :message_panel_name => "primary_messages",
        :message_panel_message => "Successfully saved jobs!"
      }
      
    @arr[:organisation_id] = @organisation.id if @organisation

    respond_to do |format|
      format.json {render :json => @arr.to_json, :callback => params[:callback]}
    end  
  end
  
  #
  # --- PROCESS
  #
  # The URL can take one of the following forms
  #  A. Bookmark - search results and generic pages - not job-related
  #  B. Job-related - job ad page, job apply page etc
  #  
  # 1. Find the page type
  # 
  # 2. [page_type = search_results]
  #  - [bookmarked]
  #   + display 'bookmarked' message
  #   + Allow user to 'unbookmark' the link
  #  - [not bookmarked]
  #   + display 'bookmark' field, allow user to tag the bookmark
  #
  # 3. [page_type = job-related page]
  #  - 
  #
  def bl_bookmark_site
    
    # Store 'session_flyc_token' in database with IP as unique identifier
    # as using Post from cross-domain, the session is somehow lost.
    # Checking 'session' against the IP will ensure there is some consistency with this
#    puts "XXXX: "+ session[:user].first_name if session[:user]

#    bl_facebook_test

    if session[:user].person_type_id == 0 # Admin
      bl_admin_bookmark_site
      return
    end
    
    # ---------------------- 1. Set the general attributes ----------------------
    @state = 2
    @url_o = Addressable::URI.parse(params[:url])
    @is_site_detected = false
    @site_detected = "Unknown"
    @site_detected = "Unable to detect source URL" if !@url_o
    @page_detected = "Unknown"
    @website_fields = Array.new
    @site_url = @url_o.host
    @is_blank_page_selected = false
    @role_application = nil
    @tab = 1
    
    @page = nil
    @page_type = 0 # Default = Unknown
    @content_html = nil
    
    # ---------------------- START ----------------------
    @organisation = Organisation.find(
      :first, 
      :conditions => [ "website like ?", "%" + @url_o.host])
    
    # A. In case site doesn't exist
    # --------------------------------------------------------
    if !@organisation
      @organisation = Organisation.new
      @organisation.website = @url_o.host
      @organisation.status_id = 3 # Requires admin confirmation
      @organisation.save(false)
     
    # B. In case site exists, but page doesn't exist
    # --------------------------------------------------------
    #  - Check first for normal pages
    #  - Check for 'blank' pages
    elsif @organisation.status_id == 1 || @organisation.status_id == 2 # 'Quickly' added or complete 'Organisation' entities. not 'status_id' = 3
      @site_detected = @organisation.name
      @is_site_detected = true
      
      @site_organisation_type = @organisation.type_id
      
      @website_pages_db = WebsiteParsingPage.find(
        :all, 
        :conditions => [ "organisation_id = ?", @organisation.id])
        
      if @website_pages_db
        @match_size = 0
        @tmp_match_size = 0
        @black_page_o = nil
        
        @website_pages_db.each do |page|
          if @url_o.path.index(page.uri_string)
            @tmp_match_size = page.uri_string.length
          end
          
          if @tmp_match_size && @tmp_match_size >= @match_size
            @match_size = @tmp_match_size
            @tmp_match_size = 0
            @page = page
          end
          
          if !@black_page_o && page.uri_string && !page.uri_string.blank? && page.uri_string == "{blank}"
            @black_page_o = page 
          end 
        end
        
        # in case there was no match, check if there is a blank record match
        @page = @black_page_o if !@page && @black_page_o && @url_o.path == "/"
          
        if @page
          @page_id = @page.id
          @page_type = @page.page_type
          @page_type_path = @page.uri_string
        end
      end
    end
  
    # C. If 'page' was identified, I.e., can perform auto-populate of field
    # --------------------------------------------------------
    if @page
      
      @page_detected = WebsiteParsingPage.page_types.rassoc(@page.page_type)[0]
      
      # Get the list of all 'uri_string' elements so auto-grabbing could occur
      @website_fields_db = WebsiteParsingField.find(
        :all,   
        :conditions => [ "website_parsing_page_id = ?", @page.id])
      
      # D. If 'page_type' is search results, try and search for a bookmark
      # --------------------------------------------------------
      if @page.page_type == 1
        
        # D.1. Here the search for a bookmark will occur
 
        # D.2. Currently, auto-grab the fields and present on screen
        
      # E. Otherwise, try and search for a 'role' or 'application'
      # --------------------------------------------------------
      else
        # E.1. First, search for a role based on the URL (quickest and most accurate comparison)
        @role_applications = RoleApplication.find_by_sql(
          "select role_applications.* " +
          "from roles, role_applications " + 
          "where role_applications.role_id = roles.id and " +
            "roles.external_link = '" + @url_o.to_s + "'")
            
        # E.2. Second, if first search wasn't successful, search by both job title and description
        
        # E.1. If 'role' was identified, display message, role already exists ...
        # --------------------------------------------------------
        if @role_applications && @role_applications[0]
          @role_application = @role_applications[0]
          @role = @role_application.role
          @state = 4
          
        # E.2. If 'role' couldn't be found, auto-grab the role details
        # --------------------------------------------------------
        else
          @role_application = RoleApplication.new
          @role = Role.new
        end
      end
      
    # F. Page wasn't found, notify admin to configure the page
    # --------------------------------------------------------
    # ** Later implementation, allow user to:
    #  + Manually enter the role details
    #  + User can select the type of page this is (Search results, etc), display relevant fields in that case
    #  + Provide the 'selector gadget' for the user to auto-grab the fields
    #   = This will also notify the admin of the proposed selections for consideration 
    else
      @page_type = 0 # Unknown
    end
    
    # json structure
    @arr = {
        :status => "200",
        :action => "bookmark",
        :page_type => @page_type,
        :jquery_css_selectors_arr => @website_fields_db,
        :logged_in_details_html => render_to_string(:partial => '/bookmarklet/logged_in_panel.html'),
        :primary_messages_html => render_to_string(:partial => '/bookmarklet/primary_messages_panel.html'),
        :content_html => render_to_string('/bookmarklet/bookmark_site.html'),
        :buttons_html => render_to_string(:partial => '/bookmarklet/buttons_panel.html')
      }
      
    @arr[:organisation_id] = @organisation.id if @organisation
    @arr[:role_application_id] = @role_application.id if @role_application
    @arr[:page_id] = @page.id if @page
    @arr[:url_path] = @url_o.path
      
    respond_to do |format|
      format.json {render :json => @arr.to_json, :callback => params[:callback]}
    end
  end
  
  def bl_parse_page
    @html_doc = Nokogiri::HTML(open(session[:url_source].to_s))
    @parsed_page_h = Hash.new
    
    @job_title_o = @html_doc.xpath("//h1[@class='jobtitle']")
    @company_o = @html_doc.xpath("//div[@class='content']/h1/span")
    @location_o = @html_doc.xpath("//dl[@class='classifiers']/dd")
    @description_o = @html_doc.xpath("//div[@class='templatetext']") 
    
    @parsed_page_h[:title] = @job_title_o.first.text if @job_title_o
    @parsed_page_h[:company] = @company_o.first.text.sub(/^-/, '').strip if @company_o
    @parsed_page_h[:location] = @location_o.first.text.strip if @location_o
    @parsed_page_h[:description] = @description_o.first.inner_html if @description_o
    
#    @parsed_page_h[:company] = @doc.xpath('//*[contains(concat( " ", @class, " " ), concat( " ", "seeker-frame", " " ))]/div/h1/span').first.inner_html.sub(/^-/, '').strip
#    @parsed_page_h[:location] = @doc.xpath('//*[contains(concat( " ", @class, " " ), concat( " ", "classifiers", " " ))]/dd').first.inner_html.strip
    
    @state = 1
    
    respond_to do |format|
      format.js {render '/bookmarklet/parse_page.js', :layout => false}
    end
  end
  
  def bl_get_unknown_panel
    # Set the default display to 'job' page
    @page_type = params[:page_type].to_i
    @tab = "new_role"
    
    # Set 'job' the default panel to show
    # Set the default 'role_id' for it as well (i.e. '-1')
    @arr = {
        :status => "200",
        :action => "get_unknown_panel",
        :default_page_type => 2,
        :role_id => -1,
        :panel_html => render_to_string(:partial => '/bookmarklet/bookmark_job_panel.html'),
        :widget_tabs_html => render_to_string(:partial => '/bookmarklet/widget_tabs.html'),
        :message_panel_name => "primary_messages",
        :message_panel_message => "This page is not known. The 'flyc' master was informed, he will configure this page ASAP. In the meantime, choose the type for yourself..."        
      }

    respond_to do |format|
      format.json {render :json => @arr.to_json, :callback => params[:callback]}
    end
  end
  
  def bl_get_facebook_panel
    
    @action = "get_facebook_panel"
    
    @arr = {
        :status => "200",
        :action => "get_facebook_panel",
        :panel_html => render_to_string(:partial => '/bookmarklet/facebook_panel.html'),
        :buttons_html => render_to_string(:partial => '/bookmarklet/buttons_panel.html')
      }

    respond_to do |format|
      format.json {render :json => @arr.to_json, :callback => params[:callback]}
    end 
  end  
  
  def bl_get_job_panel
    @jobs_to_insert_h = Hash.new
    @page_type = params[:page_type].to_i
    @state = 3 # for buttons panel
    @tab = "job"
    
    params[:jobs].each do |job_k, job_v|
      @jobs_to_insert_h[job_k] = Role.new
      @jobs_to_insert_h[job_k].title = params[:jobs][job_k]["-1"]
      @jobs_to_insert_h[job_k].description = params[:jobs][job_k]["-2"]
    end
    
    if params[:role_id]
      @role = Role.find_by_id(params[:role_id])
    end
    
    @arr = {
        :status => "200",
        :action => "get_job_panel",
        :role => @role,
        :panel_html => render_to_string(:partial => '/bookmarklet/bookmark_job_panel.html'),
        :buttons_html => render_to_string(:partial => '/bookmarklet/buttons_panel.html'),
        :widget_tabs_html => render_to_string(:partial => '/bookmarklet/widget_tabs.html')
      }

    respond_to do |format|
      format.json {render :json => @arr.to_json, :callback => params[:callback]}
    end 
  end
  
  def bl_get_apply_panel
    @page_type = params[:page_type].to_i
    @tab = "apply"
    
    @arr = {
        :status => "200",
        :action => "get_apply_panel",
        :panel_html => render_to_string(:partial => '/bookmarklet/bookmark_apply_panel.html'),
        :widget_tabs_html => render_to_string(:partial => '/bookmarklet/widget_tabs.html')
      }

    respond_to do |format|
      format.json {render :json => @arr.to_json, :callback => params[:callback]}
    end
  end
  
  def bl_get_new_role_panel
    @page_type = params[:page_type].to_i
    @state = 3 # for buttons panel
    @tab = "new_role"
    
    if params[:role_id]
      @role = Role.find_by_id(params[:role_id])
    end
    
    @arr = {
        :status => "200",
        :action => "get_new_role_panel",
        :role => @role,
        :role_id => -1,
        :panel_html => render_to_string(:partial => '/bookmarklet/bookmark_job_panel.html'),
        :buttons_html => render_to_string(:partial => '/bookmarklet/buttons_panel.html'),
        :widget_tabs_html => render_to_string(:partial => '/bookmarklet/widget_tabs.html')
      }

    respond_to do |format|
      format.json {render :json => @arr.to_json, :callback => params[:callback]}
    end
  end
  
  def bl_get_actions_panel
    @page_type = params[:page_type].to_i
    @tab = "actions"
    
        # *************************************
    # DAY SELECTOR
    # *************************************
    
    # Create the day drop-down
    t = Time.now
    
    # %W - week number (Monday being first day of week)
    # %U - week number (Sunday being first day of week)
    w = t.strftime("%W").to_i
    m = t.strftime("%m").to_i 
    
    @action_day_options_arr = [['* ' + t.strftime("%B").upcase + ' *'],
      ['&nbsp;&nbsp;* ' + t.strftime("%d %b (%A)") + ' *', -1]]
      
    t = t + (60 * 60 * 24)
    
    # Iterate 90 days from today
    90.times do
      is_new_month = false
      
      if (current_month = t.strftime("%m").to_i) > m
        is_new_month = true
        @action_day_options_arr.concat([['', -1], ['' + t.strftime("%B").upcase, -1]])
        m = current_month
      end
      
      if (current_week = t.strftime("%W").to_i) > w
        @action_day_options_arr.concat([['', -1]]) if !is_new_month
#        @action_day_options_arr.concat([['- Week ' + current_week.to_s + ' -', -1]])
        w = current_week
      end
      
      if t.strftime("%w").to_i == 0 || t.strftime("%w").to_i == 6
        @action_day_options_arr.concat([['&nbsp;&nbsp;.' + t.strftime("%d %b - %A"), -1]])  
      else
        @action_day_options_arr.concat([['&nbsp;&nbsp;' + t.strftime("%d %b - %A"), -1]])
      end
      
      # Add 1 day
      t = t + (60 * 60 * 24)
    end
    
    # *************************************
    # TIMEZONE SELECTOR
    # *************************************
    
    if session[:user_country]
      @timezone_options_arr = Array.new
      @selected_country_timezone = nil
      alpha = "A"
      
      TZInfo::Country.all.sort_by { |c| c.name }.each do |c|  
        
        if c.name[0].chr != alpha
          @timezone_options_arr.concat([['', -1]])
          alpha = c.name[0].chr
        end
        
        if c.zones.length == 1
          
  #        puts "XXX: " +  c.zones[0].friendly_identifier
  #        puts "XXX: " +  c.zones[0].identifier
          
          @timezone_options_arr.concat([[c.name + ', ' + 
            c.zones[0].friendly_identifier(true) + 
            ' - ' + c.zones[0].now.strftime("%I:%M %p %d %b %a"), c.zones[0].identifier ]])
            
          if session[:user_country].country == c.name && !@selected_country_timezone
            @selected_country_timezone = c.zones[0].identifier 
          end
            
        elsif c.zones.length > 1
          
          @timezone_options_arr.concat([[c.name, -1]])
        
          c.zones.sort_by { |z| z.friendly_identifier(true) }.each do |z|
            if session[:user_country].country == c.name && !@selected_country_timezone
              @selected_country_timezone = z.identifier 
            end
              
            @timezone_options_arr.concat([['&nbsp;&nbsp;' + 
              z.friendly_identifier(true) +
              ' - ' + z.now.strftime("%I:%M %p %d %b %a"), z.identifier ]])
          end
        end          
      end
    end
    
    @arr = {
        :status => "200",
        :action => "get_actions_panel",
        :panel_html => render_to_string(:partial => '/bookmarklet/bookmark_actions_panel.html'),
        :widget_tabs_html => render_to_string(:partial => '/bookmarklet/widget_tabs.html')
      }

    respond_to do |format|
      format.json {render :json => @arr.to_json, :callback => params[:callback]}
    end
  end
  
  def bl_get_search_results_panel
    @state = 1
    @page_type_options_arr = WebsiteParsingPage.page_types
    @organisation = Organisation.find_by_id(params[:site_organisation_id])
    @url_path = params[:url_path]
    @tab = "search_results"
    
    @is_site_detected = false
    @site_detected = "Unknown"
    @site_detected = "Unable to detect source URL" if !@url_o
    @page_detected = 0
    @website_fields = Array.new
    
    # Flag the type of page found based a match between the '@url_o' and the '@sites' page attributes  
    @site_detected = @organisation.name if @organisation && @organisation.name
    
    @is_site_detected = true if @site_detected
    
    if @organisation
      @site_organisation_type = @organisation.type_id
      
      # Query will select all pages where the 'blank' page (if exists) will appear last
      @website_pages_db = WebsiteParsingPage.find(
        :all, 
        :conditions => [ "organisation_id = ?", @organisation.id],
        :select => 'id, uri_string, page_type')
    end 
      
    @state = 4
    @page = nil
    @website_field_db = nil
    @page_type = 1 # Default = 'Search results'
    @jquery_css_selector = nil
    @site_organisation_type = 3 # Default = 'job board'
    @page_type_path = ""
    @page_type_path_arr = [["-- New --", -2], 
      ["- Blank -", -1]]
    @is_blank_page_selected = false
    @inner_page = 1
    @page_id = nil
    
    if @website_pages_db
      @website_pages_db.each do |page|
        if page.uri_string && !page.uri_string.blank? && !(page.uri_string == "{blank}")
          @page_type_path_arr[@page_type_path_arr.length] = [page.uri_string, page.id]
        else
          @is_blank_page_selected = true
          @page_type_path_arr[1][1] = page.id
        end
        
        if !@page && (@is_blank_page_selected || @url_path.match(page.uri_string))
          @page = page
          @page_id = page.id
          @page_type = page.page_type
          @page_type_path = page.uri_string
            
#            break
        end 
      end
    end
    
    @arr = {
        :status => "200",
        :action => "get_search_results_panel",
        :panel_html => render_to_string(:partial => '/bookmarklet/bookmark_search_results_panel.html'),
        :widget_tabs_html => render_to_string(:partial => '/bookmarklet/widget_tabs.html')
      }

    respond_to do |format|
      format.json {render :json => @arr.to_json, :callback => params[:callback]}
    end 
  end
  
  def bl_process_bookmark_site
      
    # Store in database
    # 'Role'
    ## 1. Agency
    ## 2. Company
    @role = Role.new(params[:role])
    @role.external_link = session[:url_source].to_s
    
    # 'RoleApplication'
    ## 1. Title
    ## 2. Status
    ## 3. Closing date
    @role_application = RoleApplication.new(params[:role_application])
    @role_application.role = @role
    @role_application.person = session[:user]
    
    RoleApplication.transaction do
      begin
        failed_validation = false
        
        raise 'ERROR: No submit action defined' if !params['submit_action']
          
        ## ROLE and ROLE_APPLICATION
        failed_validation = true if !@role_application.valid?
        failed_validation = true if !@role.valid?
        raise 'ERRORS: ' + @role.errors.to_xml if failed_validation
        raise 'ERRORS: ' + @role_application.errors.to_xml if failed_validation
        
        if params['submit_action'] == 'save' || params['submit_action'] == 'save_and_close'
          
          @role_application.save(false)
          @role.save(false)
          flash[:notice] = 'Application was successfully created.'
          
        elsif params['submit_action'] == 'update' || params['submit_action'] == 'update_and_close'
          
          @role_application_existing = RoleApplication.find_by_id(params[:application_id])
          @role_application_existing.update_attributes!(params[:role_application])
          @role_application_existing.role.update_attributes!(params[:role])
          
        end

        @state = 2 if params['submit_action'] == 'save' || params['submit_action'] == 'update' 
        @state = 3 if params['submit_action'] == 'save_and_close' || params['submit_action'] == 'update_and_close'
        
        flash[:error] = nil
        
        respond_to do |format|
          format.js {render '/bookmarklet/bookmark_site.js', :layout => false}
        end
        
      rescue Exception => exc
        
        flash[:error] = exc.message
        print exc.message
        
        @state = 0
        
        respond_to do |format|
          format.js {render '/bookmarklet/bookmark_site.js', :layout => false}
        end
        
      end
    end
  end

end
