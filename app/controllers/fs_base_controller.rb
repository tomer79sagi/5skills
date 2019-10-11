require 'image_size'
# require 'tzinfo'
require 'json'

class FsBaseController < ActionController::Base
  
  include ActionView::Helpers::DateHelper
  
  helper :all # include all helpers, all the time
  
#  protect_from_forgery # See ActionController::RequestForgeryProtection for details

##  before_filter :print_headers
  
#  before_filter :cors_preflight_check
#  after_filter :cors_set_access_control_headers
  
#  before_filter :performance, :activity_logger_start, :initialize_timezone
##  after_filter :activity_logger_end

  # before_filter :initialize_timezone
  before_filter :set_defaults
  before_filter :convert_json_to_hash
  before_filter :prep_page_view_mode,
    :except => [:home, :download_file, :show_file, :view_template]
  
  # after_filter :clear_soft_messages

  FIELD_COLLECTION_TYPES = {:templates => 1, :keywords => 2, :companies => 3, :agencies => 4, :skill_keywords => 5}
  TIME_FORMAT_TYPES = {:default => 1, :time_ago => 2}
  
  PAGE_VIEW_MODES = {:other => 0, :create => 1, :view => 2, :edit => 3}
  FORM_ACTIONS = {:create => "save", :save => "save", :edit => "update", :update => "update"}
  FORM_LABELS = {:create => "Create", :edit => "Edit"}
  FORM_UPDATE_LABELS = {:create => "Create", :save => "Create", :edit => "Update", :update => "Update"}
  
  ENTITY_TYPES = {:job => 1, :job_seeker => 2}
  FS_PROFILE_TYPES = {:user_profile => 1, :template => 2, :demo => 3, :search => 4}
  FS_PROFILE_STATUS = {:draft => 1, :published => 2}

  
  
  def set_defaults
    params[:default_search_ajax_call] = "search_job_seekers"
  end
  
  #
  # This method accepts an array of 'symbolised' keys and tries to retrieve its 'value'
  # from the 'params' request Hash. It will traverse down as deep as needed to try and retrieve 
  # the right value.
  #
  # If any key along the way is null, it will return a 'blank' string => ""
  # This prevents string 'nil' checks in the views
  #
  def get_param(a_keys, string_replace_pair = nil)
    return "" if a_keys.nil?
    value = nil
    
    a_keys.each do |key|
      
      if key.nil?
        value = ""
        break
      end
      
      if value.nil?
        value = params[key]
      else
        value = value[key]
      end
      
      if value.nil?
        value = ""
        break
      end
       
    end
    
    if string_replace_pair
      value = value.to_s.gsub(string_replace_pair[0], string_replace_pair[1])
    end
    
    value
    
  end
  
  def _get_field_errors(obj, attribute)
    if obj && obj.errors && obj.errors.on(attribute)
      obj.errors.on(attribute)
    else
      nil
    end
  end
  
  
  def escape_single_quotes(str)
    return str.gsub(/[']/, '\\\\\'')
  end
  
  
  def encode_utf(str)
    Iconv.conv('UTF-8//IGNORE', 'UTF-8', str + ' ')[0..-2]
  end
  
  
  def prep_page_view_mode
    a_action_name_split = params[:action].split("_") 
    mode = a_action_name_split[0].to_sym
    
    params[:page_view_mode] = PAGE_VIEW_MODES[mode]
    params[:page_view_mode] = PAGE_VIEW_MODES[:other] if params[:page_view_mode].nil?
    
    if FORM_ACTIONS[mode]
      a_action_name_split[0] = FORM_ACTIONS[mode]
      form_action = a_action_name_split.join("_").to_sym
      
      params[:form_action] = form_action
      params[:form_label] = FORM_LABELS[mode]
      params[:form_update_label] = FORM_UPDATE_LABELS[mode]
    end
  end
  
  def hash_a_json(json_string)
    return if json_string.nil? || json_string.blank?
    
    json_hash = JSON.parse(json_string)
    json_hash
  end
  
  def convert_json_to_hash
    return if !params[:json] || params[:json] == "null"
    
    params.merge!(ActiveSupport::JSON.decode(params[:json]))
    params.delete('json') 
  end
  
  def format_time(time_as_string, format_type = TIME_FORMAT_TYPES[:default])
    case format_type
      when TIME_FORMAT_TYPES[:default]
        time_as_string = DateTime.parse(time_as_string).strftime('%d %b, %Y - %H:%M')
      when TIME_FORMAT_TYPES[:time_ago]
        time_as_string = time_ago_in_words(time_as_string) + " ago"
    end
    
    time_as_string
  end
  
  def add_ajax_start_up_actions(s_ajax_action)
    return if s_ajax_action.nil?
    
    params[:ajax_start_up_actions] = Array.new if params[:ajax_start_up_actions].nil?
    params[:ajax_start_up_actions] << s_ajax_action
  end
  
  #
  # OBJECTS stored in 'session' object
  # ----------------------------------------
  #
  # Set the following session attributes
  #
  # 1. ':person' -> holding either the 'Fs2JobSeeker' or the 'Fs2Contact' objects (holding contact information)
  # 2.  ':agency' -> holding the 'Fs2Organisation' object in case the user is a 'recruitment agent'
  # 3.  ':company' -> holding the 'Fs2Organisation' object in case the user is a 'company contact'
  # 4.  ':job' -> holding the 'job' object (active / current job) in case the user is either a 'recruitment agent' or a 'company contact'
  # 5. ':fs_profile' -> holding the 'five_skills profile' (active / current profile) 
  #
  def init_person_objects
    
    if session[:user]
    
      # --- JOB SEEKER
          
      if session[:user].user_type_id == Fs2User::USER_TYPES[:job_seeker]
        
        session[:person] = Fs2JobSeeker.find_by_user_id(session[:user].id)
        
        
      # --- EMPLOYER / RECRUITMENT AGENCY
      
      elsif session[:user].user_type_id == Fs2User::USER_TYPES[:hiring_manager] || session[:user].user_type_id == Fs2User::USER_TYPES[:recruitment_agent]
        
        session[:person] = Fs2Contact.find_by_user_id(session[:user].id)
        
        # ****************
        #  > AGENCY
        # ****************
        if session[:user].user_type_id == Fs2User::USER_TYPES[:recruitment_agent]
          # 1. Find the 'Agency'
          session[:agency] = Fs2Organisation.find_by_id(session[:person].organisation_id) if session[:person].organisation_id
          
          # 2. Find the 'Job'
          # TODO: Add support for editing all 'organization' jobs
          # if session[:agency]
          jobs = Fs2Job.find(:all, :conditions => ["agency_id = ?", session[:agency].id.to_s]) if session[:agency]
          # end 
          
          # 3. Find the 'Company' (if the job has a company associated with it)
          session[:company] = Fs2Organisation.find_by_id(session[:job].company_id) if session[:job] && session[:job].company_id
        
        # ****************
        #  > COMPANY
        # ****************
        elsif session[:user].user_type_id == Fs2User::USER_TYPES[:hiring_manager]
          # 1. Find the 'Company'
          session[:company] = Fs2Organisation.find_by_id(session[:person].organisation_id) if session[:person].organisation_id
          
          # 2. Find the 'Jobs' (currently directly related)
          # TODO: Add support for editing all 'organization' jobs
          
          # if session[:company]
          jobs = Fs2Job.find(:all, :conditions => ["company_id = ?", session[:company].id.to_s]) if session[:company] 
          # end
        end
        
        # Convert the jobs DB array into a Hash containing 'id / title' pairs
        if jobs
          
          jobs_map = jobs.inject({}) do |h, e|
            job_fs_profiles = Fs2SkillsProfile.find(:all, 
              :conditions => ["profile_type = ? AND entity_type = ? AND entity_id = ?", 
                FS_PROFILE_TYPES[:user_profile], 
                ENTITY_TYPES[:job], 
                params[:job_id]]) if @current_job
             
            job_fs_profiles.each do |job_fs_profile|
              # --- IF THE 'HIRING MANAGER' IS THE LOGGED IN USER -> find the 'my jobs' collection
              if (session[:user].user_type_id == Fs2User::USER_TYPES[:hiring_manager] && e.company_contact_id == session[:user].id) ||
                  (session[:user].user_type_id == Fs2User::USER_TYPES[:recruitment_agent] && e.agency_contact_id == session[:user].id)
                
                h[:my_jobs] = {} if h[:my_jobs].nil?
                h[:my_jobs][e.id] = {} if h[:my_jobs][e.id].nil? 
                h[:my_jobs][e.id][:fs_profiles] = {} if h[:my_jobs][e.id][:fs_profiles].nil? 
                h[:my_jobs][e.id][:fs_profiles][job_fs_porfile.id] = {} if h[:my_jobs][e.id][:fs_profiles][job_fs_porfile.id].nil?
                
                h[:my_jobs][e.id][:title] = e.title
                h[:my_jobs][e.id][:fs_profiles][job_fs_porfile.id][:profile_type] = job_fs_profile.profile_type
                h[:my_jobs][e.id][:fs_profiles][job_fs_porfile.id][:label] = job_fs_profile.label
                  
              # --- These jobs are other jobs from the same organisation
              else
                
                h[:my_company_jobs] = {} if h[:my_company_jobs].nil?
                h[:my_company_jobs][e.id] = {} if h[:my_company_jobs][e.id].nil? 
                h[:my_company_jobs][e.id][:fs_profiles] = {} if h[:my_company_jobs][e.id][:fs_profiles].nil? 
                h[:my_company_jobs][e.id][:fs_profiles][job_fs_porfile.id] = {} if h[:my_company_jobs][e.id][:fs_profiles][job_fs_porfile.id].nil?
                
                h[:my_company_jobs][e.id][:title] = e.title
                h[:my_company_jobs][e.id][:fs_profiles][job_fs_porfile.id][:profile_type] = job_fs_profile.profile_type
                h[:my_company_jobs][e.id][:fs_profiles][job_fs_porfile.id][:label] = job_fs_profile.label
                
              end
            end
            
            h 
          end # loop of 'inject'
          
          jobs_map[:active_job_id] = jobs[0].id
          session[:jobs] = jobs_map
          
        end
        
        # TEMP
        session[:jobs] = {:id => 17, :title => "Project Manager", :active_job_id => 17}
          
      end
    
    end # 'if session[:user]'
    
    # Initialise defaults (i.e. anonymous profile photo file information)
    anonymous_profile_photo_file = Fs2File.find_by_id(Fs2File::ANONYMOUS_SECRET_IDS[:profile_photo])
    
    session[:defaults] = {}
    session[:defaults][:anonymous_profile_photo_file] = anonymous_profile_photo_file if anonymous_profile_photo_file
  end
    
  
  #
  # Method that adds 'binders' to the 'params' hash.
  #
  # 'flags' takes the following options:
  #  'comma_suffix => true/false' : if to automatically include a ',' comma at the end of the chosen keyword (allowing multiple keywords)
  #  'include_image => true/false' : if to include a company's or agency's logo for each result
  #    - The system will try and find a 'file' with the 'entity_id' retrieved from the selected list item
  #
  def add_field_binder(s_field_name, s_field_id, s_ajax_call, i_field_collection_type, flags = {})
    params[:field_binders] = Hash.new if params[:field_binders].nil?
    
    flags[:comma_suffix] = false if flags[:comma_suffix].nil?
    flags[:include_image] = false if flags[:include_image].nil?
    flags[:autocomplete] = true if flags[:autocomplete].nil?
    
    params[:field_binders][s_field_name.to_sym] = {
        :field_name => s_field_name,
        :ajax_call => s_ajax_call.to_s,
        :data_type => FIELD_COLLECTION_TYPES.index(i_field_collection_type).to_s,
        :comma_suffix => flags[:comma_suffix].to_s,
        :include_image => flags[:include_image].to_s,
        :autocomplete => flags[:autocomplete].to_s        
      }
    
    params[:field_binders][s_field_name.to_sym][:onsearch] = flags[:onsearch] if flags[:onsearch] 
    params[:field_binders][s_field_name.to_sym][:field_id] = s_field_id
    
    add_field_data(i_field_collection_type) if flags[:onsearch].nil?
    
  end
  
  def add_field_data(i_field_collection_type)
    params[:field_data] = Hash.new if params[:field_data].nil?
    
    #
    # Add the collections
    #
    if params[:field_data][FIELD_COLLECTION_TYPES.index(i_field_collection_type)].nil?
      
      # --------------------------
      # TEMPLATES
      # --------------------------
      if i_field_collection_type == FIELD_COLLECTION_TYPES[:templates]
        
        params[:field_data][FIELD_COLLECTION_TYPES.index(i_field_collection_type)] =
          Fs2Template.find(:all, :select => "id, name").
            map {|template| '{id:' + template.id.to_s + ',value:"' + template.name + '"}'}.join(', ')
      
      # --------------------------
      # KEYWORDS
      # --------------------------
      elsif i_field_collection_type == FIELD_COLLECTION_TYPES[:keywords]

        params[:field_data][FIELD_COLLECTION_TYPES.index(i_field_collection_type)] =
          Fs2Keyword.find(:all, :select => "id, keyword").
            map {|keyword| '{id:' + keyword.id.to_s + ',value:"' + keyword.keyword + '"}'}.join(', ')
            
      # --------------------------
      # SKILL KEYWORDS
      # --------------------------
      elsif i_field_collection_type == FIELD_COLLECTION_TYPES[:skill_keywords]

        params[:field_data][FIELD_COLLECTION_TYPES.index(i_field_collection_type)] =
          Fs2SkillKeyword.find(:all, :select => "id, en_US").
            map {|skill_keyword| '{id:' + skill_keyword.id.to_s + ',value:"' + skill_keyword.en_US + '"}'}.join(', ')
            
      # --------------------------
      # COMPANIES
      # --------------------------
      elsif i_field_collection_type == FIELD_COLLECTION_TYPES[:companies]
        
        sql = "select " +
           "o.id org_id, o.name org_name, " + 
           "of.id file_id, of.small_dimensions dimensions " + 
          "from " +
           "fs2_organisations o LEFT JOIN " +
           "fs2_files of on (o.id = of.entity_id) " + 
          "where " + 
            "o.organisation_type = " + Fs2Organisation::ORGANISATION_TYPES[:company].to_s + " AND " +  
            "of.file_type = " + Fs2File::FILE_TYPES[:company_logo].to_s
        
        s_companies = ""
        companies = Fs2Organisation.find_by_sql(sql)
        companies.each do |org|
          if org.dimensions.nil?
            a_dimensions = Fs2File::IMAGE_JOB_SEEKER_PLACEHOLDER_SIZES[:small].split('x')
          else
            a_dimensions = org.dimensions.split('x')
          end
          
          img_width = a_dimensions[0] if a_dimensions
          img_height = a_dimensions[1] if a_dimensions
          
          s_companies += 
            '{id:"' + org.org_id.to_s + '"' + 
            ',value:"' + org.org_name + '"' +
            ',file_id:"' + org.file_id.to_s + '"' +
            ',width:"' + img_width.to_s + '"' +
            ',height:"' + img_height.to_s + '"' +              
            '},'
        end
        s_companies = s_companies.chop if !s_companies.blank?
                
        params[:field_data][FIELD_COLLECTION_TYPES.index(i_field_collection_type)] = s_companies
           
      # -------------------------- 
      # AGENCIES
      # --------------------------
      elsif i_field_collection_type == FIELD_COLLECTION_TYPES[:agencies]

        sql = "select " +
           "o.id org_id, o.name org_name, " + 
           "of.id file_id, of.small_dimensions dimensions " + 
          "from " +
           "fs2_organisations o LEFT JOIN " +
           "fs2_files of on (o.id = of.entity_id) " + 
          "where " + 
            "organisation_type = " + Fs2Organisation::ORGANISATION_TYPES[:agency].to_s + " AND " +  
            "of.file_type = " + Fs2File::FILE_TYPES[:agency_logo].to_s
          
        s_agencies = ""
        agencies = Fs2Organisation.find_by_sql(sql)
        agencies.each do |org|
          if org.dimensions.nil?
            a_dimensions = Fs2File::IMAGE_JOB_SEEKER_PLACEHOLDER_SIZES[:small].split('x')
          else
            a_dimensions = org.dimensions.split('x')
          end
          
          img_width = a_dimensions[0] if a_dimensions
          img_height = a_dimensions[1] if a_dimensions
          
          s_agencies += 
            '{id:"' + org.org_id.to_s + '"' +
            ',value:"' + org.org_name + '"' +
            ',file_id:"' + org.file_id.to_s + '"' +
            ',width:"' + img_width.to_s + '"' +
            ',height:"' + img_height.to_s + '"' +              
            '},'
        end
        s_agencies = s_agencies.chop if !s_agencies.blank?
        
        params[:field_data][FIELD_COLLECTION_TYPES.index(i_field_collection_type)] = s_agencies
      end
      
    end 
  end
  
  
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
    # my_ip = "93.172.139.218" # external IP when using my laptop 
    my_ip = request.remote_ip
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
      session[:language] = 2 if @ip_to_country && @ip_to_country['ctry'] == "IL"
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
  
  def send_s_message(metadata_params_h, body_params_h, transaction_params_h)
    body_params_h = Hash.new if !body_params_h
    body_params_h["http_host"] = request.env["HTTP_HOST"]
    
    email_type = transaction_params_h[:email_type] if transaction_params_h[:email_type]
    exchange_type = transaction_params_h[:exchange_type] if transaction_params_h[:exchange_type]
    
    return if transaction_params_h[:email_type].nil?
    
    # System email addresses
    @system_email_address = "tomer@5skills.me"
    @admin_email_address = "tomer@5skills.me"
    @member_email_address = "member@5skills.me"
    @no_reply_email_address = "no-reply@5skills.me"
    
    # System user IDs
    @system_user_id = 0
    @system_sender_name = "Tomer"
    
    metadata_params_h = Hash.new if !metadata_params_h
    
    begin
      
      metadata_params_h[:sender_email] = @system_email_address
      metadata_params_h[:sender_reply_to_email] = @system_email_address
      metadata_params_h[:sender_name] = @system_sender_name
      
      @my_messages_h = Hash.new
      @friendly_names_h2 = {"message_id" => metadata_params_h[:subject]}
              
      case email_type
        
        # ---------------------------------------------------------
        #      CV REQUESTED
        # --------------------------------------------------------- 
        when 1 # new lead
        
          if exchange_type == 1
            
            if session[:language] && session[:language] == 1
              metadata_params_h[:template] = "new_job_seeker_lead_email_EN"
              metadata_params_h[:subject] = "Job seeker! Thanks for joining 5skills.me!"
            elsif session[:language] && session[:language] == 2
              metadata_params_h[:template] = "new_job_seeker_lead_email_HE"
              metadata_params_h[:subject] = "מחפש עבודה! תודה שהצטרפת!"
            end
            
          elsif exchange_type == 2
            
            if session[:language] && session[:language] == 1
              metadata_params_h[:template] = "new_recruiter_lead_email_EN"
              metadata_params_h[:subject] = "Recruiter! Thanks for joining 5skills.me!"
            elsif session[:language] && session[:language] == 2
              metadata_params_h[:template] = "new_recruiter_lead_email_HE"
              metadata_params_h[:subject] = "מחפש מועמדים! תודה שהצטרפת!"
            end
            
          end
   
      end        
      
      # Iterate through all recipients
      metadata_params_h[:recipients].each do |recipient|
        
        next if recipient[:email].nil?
        
        # 1. Create the messages's Metadata information as a Hash
        @message_h = Hash.new
        @message_h["sender"] = '"' + metadata_params_h[:sender_name] + '"' + ' <' + metadata_params_h[:sender_email] + '>'
        @message_h["reply_to"] = '"' + metadata_params_h[:sender_name] + '" ' + '<' + metadata_params_h[:sender_reply_to_email] + '>'
        @message_h["recipients"] = '"' + recipient[:name] + '" <' + recipient[:email] + '>'
        @message_h["subject"] = metadata_params_h[:subject]
        
        body_params_h["person_name"] = recipient[:name]
        
        @mailer_email = Fs2MailerEmail.new
        @mailer_email.headers = @message_h
        @mailer_email.body_attributes = body_params_h
        @mailer_email.template = metadata_params_h[:template]
        
        # Save email in DB for 'delayed' delivery
        @mailer_email.save(false)
      
      end  
      
    rescue Exception => exc

      puts "ERROR: " + exc.to_s
      return nil
      
    end    
  end
  
  def send_message(metadata_params_h, body_params_h, transaction_params_h)
    body_params_h = Hash.new if !body_params_h
    body_params_h["http_host"] = request.env["HTTP_HOST"]
    
    email_type = transaction_params_h[:email_type] if transaction_params_h[:email_type]
    exchange_type = transaction_params_h[:exchange_type] if transaction_params_h[:exchange_type]
    
    return if transaction_params_h[:email_type].nil?
    
    # System email addresses
    @system_email_address = "system@5skills.me"
    @admin_email_address = "admin@5skills.me"
    @member_email_address = "member@5skills.me"
    @no_reply_email_address = "no-reply@5skills.me"
    
    # System user IDs
    @system_user_id = 0
    @system_sender_name = "5skills"
    
    metadata_params_h = Hash.new if !metadata_params_h
    
    begin
      
      if exchange_type == Fs2Mailer::EMAIL_EXCHANGE_TYPES[:system_to_job_seeker] || 
          exchange_type == Fs2Mailer::EMAIL_EXCHANGE_TYPES[:system_to_recruitment_agent] ||
          exchange_type == Fs2Mailer::EMAIL_EXCHANGE_TYPES[:system_to_hiring_manager]
        
        metadata_params_h[:sender_id] = @system_user_id
        metadata_params_h[:sender_email] = @system_email_address
        metadata_params_h[:sender_reply_to_email] = @no_reply_email_address
        metadata_params_h[:sender_name] = @system_sender_name
      
        @my_messages_h = Hash.new
        @friendly_names_h2 = {"message_id" => metadata_params_h[:subject]}
        
        case email_type
          
          # ---------------------------------------------------------
          #      APPLIED THROUGH SOCIAL JOB POST / 1st July, 2013
          # --------------------------------------------------------- 
          when Fs2Mailer::EMAIL_TYPES[:apply_from_social_job_post]
          
              if exchange_type == Fs2Mailer::EMAIL_EXCHANGE_TYPES[:system_to_recruitment_agent] ||
                  exchange_type == Fs2Mailer::EMAIL_EXCHANGE_TYPES[:system_to_hiring_manager]
                  
                metadata_params_h[:template] = "to_recruiter__job_application__received"
                metadata_params_h[:subject] = "New candidate for - '#{body_params_h[:job][:title]}'!"
                
              elsif exchange_type == Fs2Mailer::EMAIL_EXCHANGE_TYPES[:system_to_job_seeker]
              
                metadata_params_h[:template] = "to_job_seeker__job_application__sent"
                metadata_params_h[:subject] = "'#{body_params_h[:job][:title]}' - Successfully applied!"
                
              end

            @params_2 = {:controller => "five_skills", :action => "view_job_seeker_profile"}
          
          # ---------------------------------------------------------
          #      CV REQUESTED
          # --------------------------------------------------------- 
          when Fs2Mailer::EMAIL_TYPES[:cv_requested_for_job]
          
              if exchange_type == Fs2Mailer::EMAIL_EXCHANGE_TYPES[:system_to_recruitment_agent] ||
                  exchange_type == Fs2Mailer::EMAIL_EXCHANGE_TYPES[:system_to_hiring_manager]
                  
                metadata_params_h[:template] = "contact_cv_requested_for_job_email"
                metadata_params_h[:subject] = "You REQUESTED a CV for your job!"
                
              elsif exchange_type == Fs2Mailer::EMAIL_EXCHANGE_TYPES[:system_to_job_seeker]
              
                metadata_params_h[:template] = "job_seeker_cv_requested_for_job_email"
                metadata_params_h[:subject] = "A job REQUESTED your CV!"
                
              end

            @params_2 = {:controller => "five_skills", :action => "view_job_seeker_profile"}
          
          # ---------------------------------------------------------
          #      CV SENT
          # --------------------------------------------------------- 
          when Fs2Mailer::EMAIL_TYPES[:cv_sent_for_job]
          
              if exchange_type == Fs2Mailer::EMAIL_EXCHANGE_TYPES[:system_to_recruitment_agent] ||
                  exchange_type == Fs2Mailer::EMAIL_EXCHANGE_TYPES[:system_to_hiring_manager]
                  
                metadata_params_h[:template] = "contact_cv_sent_for_job_email"
                metadata_params_h[:subject] = "A new CV was received for your job!"
                
              elsif exchange_type == Fs2Mailer::EMAIL_EXCHANGE_TYPES[:system_to_job_seeker]
              
                metadata_params_h[:template] = "job_seeker_cv_sent_for_job_email"
                metadata_params_h[:subject] = "You sent your CV to a job!"
                
              end

            @params_2 = {:controller => "five_skills", :action => "view_job_seeker_profile"}
          
          # ---------------------------------------------------------
          #      CV REQUEST - APPROVED
          # ---------------------------------------------------------   
          when Fs2Mailer::EMAIL_TYPES[:cv_request_approved_for_job]
          
              if exchange_type == Fs2Mailer::EMAIL_EXCHANGE_TYPES[:system_to_recruitment_agent] ||
                  exchange_type == Fs2Mailer::EMAIL_EXCHANGE_TYPES[:system_to_hiring_manager]
                  
                metadata_params_h[:template] = "contact_cv_request_approved_for_job_email"
                metadata_params_h[:subject] = "Your CV request was APPROVED by the job seeker!"
                
              elsif exchange_type == Fs2Mailer::EMAIL_EXCHANGE_TYPES[:system_to_job_seeker]
              
                metadata_params_h[:template] = "job_seeker_cv_request_approved_for_job_email"
                metadata_params_h[:subject] = "You APPROVED a CV request for a job!"
                
              end

            @params_2 = {:controller => "five_skills", :action => "view_job_seeker_profile"}
            
          # ---------------------------------------------------------
          #      CV REQUEST - REJECTED
          # --------------------------------------------------------- 
          when Fs2Mailer::EMAIL_TYPES[:cv_request_rejected_for_job]
          
              if exchange_type == Fs2Mailer::EMAIL_EXCHANGE_TYPES[:system_to_recruitment_agent] ||
                  exchange_type == Fs2Mailer::EMAIL_EXCHANGE_TYPES[:system_to_hiring_manager]
                  
                metadata_params_h[:template] = "contact_cv_request_rejected_for_job_email"
                metadata_params_h[:subject] = "Your CV request was REJECTED by the job seeker!"
                
              elsif exchange_type == Fs2Mailer::EMAIL_EXCHANGE_TYPES[:system_to_job_seeker]
              
                metadata_params_h[:template] = "job_seeker_cv_request_rejected_for_job_email"
                metadata_params_h[:subject] = "You REJECTED a CV request for a job!"
                
              end

            @params_2 = {:controller => "five_skills", :action => "view_job_seeker_profile"}
          
          when Fs2Mailer::EMAIL_TYPES[:new_job_matches]

            metadata_params_h[:template] = "new_job_matches_email"
            metadata_params_h[:subject] = "New JOBS match YOUR skills!"
            @params_2 = {:controller => "five_skills", :action => "view_job_seeker_profile"}
            
          when Fs2Mailer::EMAIL_TYPES[:new_job_seeker_matches]

            metadata_params_h[:template] = "new_job_seeker_matches_email"
            metadata_params_h[:subject] = "New JOB SEEKERS match your JOB PROFILE!"
            
            case exchange_type
              
              when Fs2Mailer::EMAIL_EXCHANGE_TYPES[:system_to_recruitment_agent]
              
                @params_2 = {:controller => "five_skills", :action => "view_job_profile"}
                
              when Fs2Mailer::EMAIL_EXCHANGE_TYPES[:system_to_hiring_manager]
              
                @params_2 = {:controller => "five_skills", :action => "view_job_profile"}
                
            end
     
        end        
      
        # Iterate through all recipients
        metadata_params_h[:recipients].each do |recipient|
          
          next if recipient[:email].nil?
          
          # 1. Create the messages's Metadata information as a Hash
          @message_h = Hash.new
          @message_h["sender"] = '"' + metadata_params_h[:sender_name] + '"' + ' <' + metadata_params_h[:sender_email] + '>'
          @message_h["reply_to"] = '"' + metadata_params_h[:sender_name] + '" ' + '<' + metadata_params_h[:sender_reply_to_email] + '>'
          @message_h["recipients"] = '"' + recipient[:name] + '" <' + recipient[:email] + '>'
          @message_h["subject"] = metadata_params_h[:subject]
          
          # 2. Create the 'MailerAction' object
          @action = Fs2MailerAction::create_o(@params_2, @friendly_names_h2)
          @action.email_action_key = Digest::MD5.hexdigest(metadata_params_h[:sender_reply_to_email] + Time.now.to_s)
          
          failed_save = false
          failed_save = true if !@action.save
          raise 'ERRORS: ' + @action.errors.to_xml if failed_save
          
          # 3. Construct the core 'body' attributes for the message as a Hash
          body_params_h["redirection_key"] = @action.email_action_key 
          body_params_h["person_name"] = recipient[:name]
          
          # *. Add CV to specific outgoing email
          if (email_type == Fs2Mailer::EMAIL_TYPES[:cv_sent_for_job] ||
              email_type == Fs2Mailer::EMAIL_TYPES[:cv_request_approved_for_job] ||
              email_type == Fs2Mailer::EMAIL_TYPES[:apply_from_social_job_post]) && 
              (exchange_type == Fs2Mailer::EMAIL_EXCHANGE_TYPES[:system_to_recruitment_agent] ||
              exchange_type == Fs2Mailer::EMAIL_EXCHANGE_TYPES[:system_to_hiring_manager]) &&
              (body_params_h[:job_seeker] && body_params_h[:job_seeker][:cv])
              
            body_params_h["attachments"] = {
              body_params_h[:job_seeker][:cv][:file_id] => {
                :name => body_params_h[:job_seeker][:cv][:file_name],
                :path => body_params_h[:job_seeker][:cv][:file_path],
                :mime_type => body_params_h[:job_seeker][:cv][:file_mime_type]}}
                
          end
          
          @mailer_email = Fs2MailerEmail.new
          @mailer_email.headers = @message_h
          @mailer_email.body_attributes = body_params_h
          @mailer_email.template = metadata_params_h[:template]
          
          # TESTING ONLY: Replace this line with the subsequent line to get instant email delivery.
#          Fs2Mailer.deliver_init(@mailer_email.headers, @mailer_email.body_attributes, @mailer_email.template)
          
          # Save email in DB for 'delayed' delivery
          @mailer_email.save(false)
        
        end      
       
      end
      
    rescue Exception => exc

      puts "ERROR: " + exc.to_s
      return nil
      
    end    
  end
    
end
