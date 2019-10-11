require 'image_size'
# require 'yaml'

class FsJobController < FsOrganisationController
  
  def prep_match_info(selected_job_seeker_id)
    search_entities(ENTITY_TYPES[:job_seeker])
    
    if @js_results_array
      
      @js_results_array.each do |job_seeker|
        job_seeker_id = job_seeker[0]
        job_seeker_obj = job_seeker[1]
        
        if selected_job_seeker_id.to_i == job_seeker_id
          @job_seeker_match_info = job_seeker_obj
          return
        end
      end
      
    end
  end

  def find_jobs
    respond_to do |format|
    
      format.html {
      
        add_skills_profile_binders("search_jobs", true)
#        add_field_binder("search_template-name", "search_template-id", "view_template_and_search", FIELD_COLLECTION_TYPES[:templates])
        
        render 'find_jobs.html', :layout => 'five_skills'
      }
      
    end
    
  end  
  
  def search_jobs
    @fs_results = search_entities_2({:request_fs_profile => @request_fs_profile}, {:entity_type => ENTITY_TYPES[:job]})
    
    # Save results in session
    # session[:matches] = @js_results_array
    
    respond_to do |format|
      
      format.json {
        @arr = {
            :status => "200",
            :action => params[:action],
            :results => @fs_results
          }
          
        render :json => @arr.to_json, :callback => params[:callback] 
      }
      
    end    
  end
  
  
  def a_recruiter_home
    
    _recruiter_routing
    
  end
  
  def a_recruiter_restart
    
    reset_session
    
    render 'a_recruiter_home.html', :layout => 'a_recruiter_home_layout'
    
  end  
  
  def _recruiter_routing
    
    
    # -- X. USER ROUTING
    
    if session[:user]
      
      if session[:user].status_id == Fs2User::USER_STATUSES[:linkedin_signed_in]
        
        is_job_routing = true
        
        # Prepare the 'session_ids'
        @session_ids = URI::escape({
          :user_id => session[:user].id.to_s,
          :recruiter_id => session[:recruiter_id].to_s,
          :user_connector_id => session[:user_connector_id].to_s,
          :job_id => session[:job_id],
          :job_status_id => session[:job_status_id]
        }.to_json)
        
        
        # -- In case there is no 'job_status_id' defined or the 'status_id' == DRAFT
        if session[:job_id] && (session[:job_status_id].nil? || session[:job_status_id].to_i == Fs2Job::STATUS[:draft])
      
          render 'a_recruiter_publish_job.html', :layout => 'a_recruiter_inner_layout'
          
        elsif session[:job_status_id].to_i == Fs2Job::STATUS[:ready_for_publishing]
          
          @aa = "__w__a_recruiter__job_publishing_home"
          render 'a_recruiter_publish_job.html', :layout => 'a_recruiter_inner_layout'
          # render 'a_recruiter_job_publishing_home.html', :layout => 'a_recruiter_job_publishing_home_layout'
        
        else # -- Temporary, reset the 'is_job_routing' to false so the 'homepage' will be shown
          
          is_job_routing = false
          
        end
        
      end
      
    end
    
    
    render 'a_recruiter_home.html', :layout => 'a_recruiter_home_layout' if !is_job_routing
    
  end  
  
  def a_recruiter_publish_job
    
    _recruiter_routing
    
    # -- X. 
    
    # Prepare the 'session_ids'
    # @session_ids = URI::escape({
      # :user_id => session[:user].id.to_s,
      # :recruiter_id => session[:recruiter_id].to_s,
      # :user_connector_id => session[:user_connector_id].to_s
    # }.to_json)
    
    # render 'a_recruiter_publish_job.html', :layout => 'a_recruiter_inner_layout'
  end  
  
  
  def a_recruiter_job_publishing_home
    
    _recruiter_routing
    
    # render 'a_recruiter_job_publishing_home.html', :layout => 'a_recruiter_job_publishing_home_layout'
  end  
  
  
  def recruiter_home
    
    
    # ------------------------- DB Stuff
    
    # -- SECOND TEST -- 28/10/13
    
    # -- Fetch all 'user_profile' user templates for processing
    
    fs_profiles = ___fetch_skills_profiles({:profile_type => 'user_profile'})
    
    # if fs_profiles
    if 1 == 2
      
      # --- 1 - 'algorithm_handles' TABLE
      
      sql_handles = "insert into fs2_algorithm_handles" + 
        " (fs_profile_id, skill_industry_id, skill_category_id, skill_id, skill_rel_strength, skill_years_exp, skill_priority) values"
          
      sql_values = "insert into fs2_algorithm_values" + 
        " (fs_profile_id, skill_industry_id, skill_industry_name, skill_category_id, skill_category_name, skill_id, skill_name, skill_years_exp, skill_priority) values"
          
      fs_profiles.each do |id, object|
        
        # SKILLS exist --> Add them to the SQL statement
        if !id.to_s.starts_with?('_') && object[:skills] && !object[:skills].empty?
          
          object[:skills].each do |skill|
            
            next if skill.nil?
            
            if skill[:industry]
              industry_id = db_prep(skill[:industry][0])
              industry_name = db_prep(skill[:industry][1])
            end
            
            if skill[:category]
              category_id = db_prep(skill[:category][0])            
              category_name = db_prep(skill[:category][1])
            end
            
            # SKILL (REL STRENGTH 1)
            if skill[:skill] && skill[:skill][0]
              sql_handles += " (#{id}, #{industry_id}, #{category_id}, #{db_prep(skill[:skill][0])}, 1, #{db_prep(skill[:years_exp])}, #{db_prep(skill[:priority])}),"
              sql_values += " (#{id}, #{industry_id}, #{industry_name}, #{category_id}, #{category_name}, #{db_prep(skill[:skill][0])}, #{db_prep(skill[:skill][1])}, #{db_prep(skill[:years_exp])}, #{db_prep(skill[:priority])}),"
            end
            
            # SKILL - REL STRENGTH 2
            if skill[:related_strong] && !skill[:related_strong].empty?
              skill[:related_strong].each do |related_skill|
                sql_handles += " (#{id}, #{industry_id}, #{category_id}, #{db_prep(related_skill[0])}, 2, #{db_prep(skill[:years_exp])}, #{db_prep(skill[:priority])}),"
              end
            end
            
            # SKILL - REL STRENGTH 3
            if skill[:related_some] && !skill[:related_some].empty?
              skill[:related_some].each do |related_skill|
                sql_handles += " (#{id}, #{industry_id}, #{category_id}, #{db_prep(related_skill[0])}, 3, #{db_prep(skill[:years_exp])}, #{db_prep(skill[:priority])}),"
              end
            end
          end
        end
      end
      
      # Remove the last ',' added
      sql_handles = sql_handles.chop
      sql_values = sql_values.chop
      
      # (1) Delete all records, (2) Reset auto-increment, (3) Insert new records
      Fs2AlgorithmHandle.connection.execute("DELETE from fs2_algorithm_handles where id > 0;")
      Fs2AlgorithmHandle.connection.execute("ALTER TABLE fs2_algorithm_handles AUTO_INCREMENT = 1;")
      Fs2AlgorithmHandle.connection.execute(sql_handles)
      
      # --- 2 - 'algorithm_values' TABLE
      
      # (1) Delete all records, (2) Reset auto-increment, (3) Insert new records
      Fs2AlgorithmValue.connection.execute("DELETE from fs2_algorithm_values where id > 0;")
      Fs2AlgorithmValue.connection.execute("ALTER TABLE fs2_algorithm_values AUTO_INCREMENT = 1;")
      Fs2AlgorithmValue.connection.execute(sql_values)
      
    end
    # ------------------------- DB Stuff
    
    
    executable_sql =
      "select" + 
        " sk.keyword name, skls.keyword_id, COUNT(skls.skills_profile_id) as cnt_profiles" +
        # " sk.en_us name, skls.keyword_id, COUNT(skls.skills_profile_id) as cnt_profiles" +  
      " from" + 
        " fs2_skills skls" + 
        " join fs2_keywords sk on (sk.id = skls.keyword_id)" +
        # " join fs2_skill_keywords sk on (sk.id = skls.keyword_id)" + 
        " join fs2_skills_profiles sp on (sp.id = skls.skills_profile_id)" + 
      " where" + 
        " skls.keyword_id > 0 AND sp.entity_type = #{ENTITY_TYPES[:job_seeker]} AND sp.profile_type = #{FS_PROFILE_TYPES[:user_profile]}" + 
      " GROUP BY skls.keyword_id" + 
      " order by cnt_profiles desc, name asc"
    
    # 1. Grab the skills from the database, sorted by job seekers with those skills
    #  --- First step, ignore the priority. Still need to consider how to implement it
    @sorted_skills = Fs2Keyword.find_by_sql(executable_sql)

    @include_counters = true
    
        
    # * Return the following core attributes (for testing)
    #  contact_id (recruiter): 32 - Tomer Sagi
    #  user_id (recruiter): 59
    #  job_id: 164
    @_user_id = 59
    
    
    # --- DEMO
    
    @_demo__job_id = params[:job_id] if params[:job_id]
    
        
    render 'MVP2_recruiter_home.html', :layout => '__recruiter_home_layout'
  end
  
  def db_prep(value)
    if value.nil?
      value = "NULL"
    elsif value.instance_of?(String)
       value = "'" + value + "'"
    end
    
    value
    
  end
  
  # -- Retrieve the 5skills specific job publishing information:
  #
  # 1. Groups (required, selected, missing etc.)
  #
  def ajax_get_job_publishing_info
    
    # -- 1 - Get the job object
    
    job = fetch_job_profile(params[:job_id])
    user_id = params[:user_id]
    
    # -- 2 - Get the associated fs_profile object
    # -- 3 - Get the associated skills' categories and industries
    # -- 4 - Query fs2_map_skill_to_publishing_channels to grab the list of channels (i.e. groups in this case) to publish to
    #   LOGIC:
    #     Try and reach the widest reach (include all industry, category and skill groups)
    #     Include all industries, categories and skills
    
    data = {}
    data[:required_channels] = _get_required_channels("by_category_id", 999999)
    # data[:required_groups] = _get_required_groups("by_fs_profile_id", job[:fs_profiles][:info][:active_fs_profile_id])
    
         
    # -- 5 - Construct the list of groups available to the user (ones the user is a member of and one's missing)
    
    @arr = do_linkedin("my_job__publishing_groups", data, {:accept => "ajax_it,'get_job_publishing_info'", :cancel => "alert,'Cancel'"})
    
    
    # -- Check if an AUTH-ERR was raised -> jump to the 'rendering' part
    if @arr[:status] != "50"
    
      # -- 6 - Check the status of the channels of the user, add new entries if the groups don't exist
      
      # -- Iterate through all required channels
      # Collect the paid 'group_id' / 'membership_status'
      #
      user_groups = []
      @arr[:job__publishing_info][:required_groups][:values].each { |req_g| user_groups << [ req_g['_key'], req_g['membershipState']['code'] ] }
      @arr[:job__publishing_info][:missing_groups][:values].each { |miss_g| user_groups << [ miss_g[:response_object]['id'], miss_g[:response_object]['relationToViewer']['membershipState']['code'] ] }
      
      
      sync_user_publishing_channels(user_id, user_groups, data[:required_channels])
      
    end  # if @arr[:status] != "50"
        
        
    respond_to do |format|
      format.json { render :json => @arr.to_json, :callback => params[:callback] }
    end
     
  end
  
  
  
  # -- Retrieve the 5skills specific job publishing information:
  #
  # 1. Groups (required, selected, missing etc.)
  #
  def ajax_a_recruiter_publish_job
    
    @arr = do_linkedin(
      "publish_my_job", 
      {:selected_groups => params[:selected_groups]},
      {:accept => "ajax_it,'a_recruiter__publish_job',", :cancel => "alert,'Cancel'"})
        
    respond_to do |format|
      format.json { render :json => @arr.to_json, :callback => params[:callback] }
    end
     
  end   
  
  
  # -- Retrieve the job status
  #
  def ajax_get_job_status
    
    @arr = {
      :status => "200",
      :action => "get_job_status"
    }
    
    
    # -- 1 - Retrieve the job status
    job_id = params[:job_id]
    
    if job_id
      
      
      # -- 1 - Get the JOB object
      
      job_profile = fetch_job_profile(job_id.to_i)      
      
      @arr[:publishing_stats] = __get_job_publishing_stats(job_id)
      @arr[:application_stats] = __get_job_application_stats(job_profile)
      
      
    # -- No 'job_id' provided
    else
      
      @arr[:status] = "101"
    end
    
        
    respond_to do |format|
      format.json { render :json => @arr.to_json, :callback => params[:callback] }
    end
     
  end     
  
  
  # -- Retrieve the 5skills specific job publishing information:
  #
  # 1. Groups (required, selected, missing etc.)
  #
  def ajax_publish_job
    
    @arr = do_linkedin("publish_my_job", nil, {:accept => "ajax_it,'publish_job',", :cancel => "alert,'Cancel'"})
        
    respond_to do |format|
      format.json { render :json => @arr.to_json, :callback => params[:callback] }
    end
     
  end   
  
  
  def fajax__publish_job
    
    
    # Initial state = Success - optimistic
    job = nil
    @arr = {
      :status => "200",
      :action => "publish_job",
      :session_ids => {}
    }
    
    
    # --- 1. Validate and check errors
    
    begin
      
      
      # -- 1. Check FIELD values are inserted
      
      # TODO: Enable '_upload_files' to accept 'entity_type' and 'entity_type_id'
      uploaded_files = _upload_files({:upload_logo => [nil, nil]}, true)
      job = Fs2Job.new({:title => get_param(['job__title']), :teaser => get_param(['job__teaser']), :location => get_param(['job__location'])})
      recruiter = create_organization({:name => get_param(['recruiting_company__name'])}, get_param(['recruiting_company__type']))
          
          
      valid_objects = {:job => job.valid?, :recruiter => recruiter.valid?, :recruiter_logo => uploaded_files[:logo].valid?}
      # valid_objects = {:job => job.valid?, :recruiter => recruiter.valid?}
      
      # -- Check if any of the objects has an INVALID object, i.e. failed validation
      if valid_objects.has_value?(false)
        
                
        # TODO: Place 'field_has_error?' as a method in a 'Fs2ActiveRecord' class so all models have it
        @arr[:errors] = {
          "form" => {
            "id" => get_param(["form", "id"]),
            "instance_number" => get_param(["form", "instance_number"]) 
          },
          "job__title" => _get_field_errors(job, :title),
          "job__teaser" => _get_field_errors(job, :teaser),
          "job__location" => _get_field_errors(job, :location),
          "recruiting_company__name" => _get_field_errors(recruiter, :name),
          "upload_logo[fs2_file]" => _get_field_errors(uploaded_files[:logo], :fs2_file)
        }
        
        raise 'Error' if @arr[:errors] && !@arr[:errors].empty?
        
      end  
      
      
      # -- X. SUCCESS
      
      # -- 1. First, create the organization
      
      save_job_params = {:status_id => Fs2Job::STATUS[:draft]}
      
      if get_param(["recruiting_company__type"]).to_i == Fs2Organisation::ORGANISATION_TYPES[:agency]
        params[:agency] = {:name => get_param(["recruiting_company__name"])}
        save_job_params[:agency_logo] = uploaded_files[:logo]
      end            
       
      if get_param(["recruiting_company__type"]).to_i == Fs2Organisation::ORGANISATION_TYPES[:company]
        params[:company] = {:name => get_param(["recruiting_company__name"])}
        save_job_params[:company_logo] = uploaded_files[:logo]
      end
      
      
      # -- X. Save the job profile. Include (1) company profile, OR (2) agency profile..
      job = __save_job_profile(save_job_params)
      
      
      # -- X. Upload the logo to the cloud for watermarking
      
      uploaded_image_raw = Cloudinary::Uploader.upload(uploaded_files[:logo].path, :public_id => uploaded_files[:logo].id.to_s + "_w")


      @arr[:session_ids][:job_id] = job.id if job
   
      
    rescue Exception => exc
      
      # TODO: Add file delete here
      uploaded_files[:logo].delete
      
      @arr[:status] = "101"
      
    end
    
    
    # -- X. Now update the status of the job
    
    job.update_attribute(:status_id, Fs2Job::STATUS[:ready_for_publishing])
    
    
    # -- X. Render the JS
    
    render_js_parent(@arr.to_json)
    
  end
  
  
  def ajax__a_recruiter__get_linkedin_groups   
    
    my_profile = do_linkedin(11)
    
    
    # -- 1 - SUCCESS (no 'status' attribute)
    
    if my_profile && my_profile['status'].nil?
      @arr = {
          :status => "200",
          :action => "get_social_groups",
          :message => "Successfully saved profile!",
          :groups_obj => my_profile
        }
        
        
    # -- 2 - FAILED ('group-membership' access NOT AVAILABLE)
        
    elsif my_profile && my_profile['status'].to_i == 403 && my_profile['message'] == "Access to group-memberships denied"
      @arr = {
          :status => "50",
          :action => "get_social_groups",
          :message => 'Errors were found in the fields below, please check the messages next to each field',
          :auth_url => get_provider_auth_url
        }
    
    
    # -- 3 - FAILED (no LIVE LinkedIn connector available)
        
    elsif my_profile.nil? || (my_profile && my_profile[:fs_obj])
      
      @arr = {
          :status => "50",
          :action => "get_social_groups",
          :message => 'Errors were found in the fields below, please check the messages next to each field',
          :auth_url => my_profile[:fs_obj][:auth_url]
        }
        
    end
        
    respond_to do |format|
      format.json { render :json => @arr.to_json, :callback => params[:callback] }
    end
    
  end
  
  # -- This method replaces the 'ajax_get_social_groups' used in a previous version
  #
  # March, 2014: This method is used by the new recruiter-focused interface
  #
  def ajax_get_linkedin_groups
    
    
    # -- 1 - Get INITIAL LinkedIn groups   
    
    _raw_groups = fetch_publishing_channels(params[:user_id])
    linkedin_groups = []
    
    
    # -- 1 - Set up the WALL channel
    
    linkedin_groups << {
      :channel_id => -1,
      :channel_name => "Tomer Sagi - Wall",
      :channel_url => "http://cnn.com/",
      :channel_logo_url => "http://m.c.lnkd.licdn.com/mpr/mpr/wc_200_200/p/5/005/010/126/2481c62.jpg",
      :channel_members_count => 0
    }
    
    
    # -- 2 - Set up the 'MY COMPANIES' channels
    
    linkedin_groups << {
      :channel_id => -5,
      :channel_name => "Company pages - Coming soon...",
      :channel_url => "http://5skills.me/",
      :channel_logo_url => "http://m.c.lnkd.licdn.com/media/p/2/000/1a6/269/23d34f5.png",
      :channel_members_count => 0
    }
    
    
    # -- 3 - Retrieve the CHANNEL status
    
    channel_stats = __get_job_channel_stats(params[:job_id]) if params[:job_id]
    
    # -- The link to construct for displaying the link to the LinkedIn post:
    #   Raw 'post_key' data: 'g-5112233-S-5891259836846346240'
    #   Format: https://www.linkedin.com/groupItem?view=&gid={group_id}&type=member&item={post_id}
    #     'group_id' = g-{5112233}-S-5891259836846346240
    #     'post_id' = g-5112233-S-{5891259836846346240}
    #   Example: https://www.linkedin.com/groupItem?view=&gid=5049608&type=member&item=5928885311366004740
    
    
    # -- 4 - Prepare all CHANNELS for display
    
    if _raw_groups && !_raw_groups.empty?
      
      _raw_groups.each do |group|
        linkedin_groups << {
          :channel_id => group[:channel_id],
          :channel_name => group[:channel_name],
          :channel_url => group[:site_group_url],
          :channel_logo_url => group[:small_logo_url],
          :channel_members_count => group[:num_members]
        }
      end
      
      @arr = {
          :status => "200",
          :action => "get_linkedin_groups",
          :message => "Successfully retrieve the user's linkedin groups",
          :groups => linkedin_groups
        }
        
        
    # -- 5 - FAILED
        
    else
      @arr = {
          :status => "50",
          :action => "get_linkedin_groups",
          :message => 'No groups were found for user',
        }
        
    end
        
    respond_to do |format|
      format.json { render :json => @arr.to_json, :callback => params[:callback] }
    end
    
  end  
    
  
  
  def ajax_get_social_groups
    
    
    my_profile = do_linkedin("my_groups")
    
    
    # -- 1 - SUCCESS (no 'status' attribute)
    
    if my_profile && my_profile['status'].nil?
      @arr = {
          :status => "200",
          :action => "get_social_groups",
          :message => "Successfully saved profile!",
          :groups_obj => my_profile
        }
        
        
    # -- 2 - FAILED ('group-membership' access NOT AVAILABLE)
        
    elsif my_profile && my_profile['status'].to_i == 403 && my_profile['message'] == "Access to group-memberships denied"
      @arr = {
          :status => "50",
          :action => "get_social_groups",
          :message => 'Errors were found in the fields below, please check the messages next to each field',
          :auth_url => get_provider_auth_url
        }
    
    
    # -- 3 - FAILED (no LIVE LinkedIn connector available)
        
    elsif my_profile.nil? || (my_profile && my_profile[:fs_obj])
      
      @arr = {
          :status => "50",
          :action => "get_social_groups",
          :message => 'Errors were found in the fields below, please check the messages next to each field',
          :auth_url => my_profile[:fs_obj][:auth_url]
        }
        
    end
        
    respond_to do |format|
      format.json { render :json => @arr.to_json, :callback => params[:callback] }
    end
    
  end  
  
  
  def ajax_post_job_to_social_group
    my_response = do_linkedin(12)
    
    if my_response
            
      @arr = {
          :status => "200",
          :action => "post_job_to_social_group",
          :message => "Successfully saved profile!"
        }
        
    else
      
      @arr = {
          :status => "101",
          :action => "post_job_to_social_group",
          :message => 'Unknown error'
        }
        
    end
        
    respond_to do |format|
      
      format.json {  
        render :json => @arr.to_json, :callback => params[:callback] 
      }
      
    end    
  end

  
  def manage_job_settings
  end
  
  def update_job_settings
  end
  
  def create_job_profile
    # @upload_files = Hash.new
    # @job = {
      # :j_id => nil,
      # :c_name => "",
      # :a_name => "",
      # :cc_full_name => "",
      # :ac_full_name => ""
    # }
#     
    # # add_skills_profile_binders("search_jobs", true)
# 
    # if session[:user].user_type_id == Fs2User::USER_TYPES[:recruitment_agent]
      # add_field_binder("search_agency-name", "search_agency-id", 
        # "view_agency_summary", FIELD_COLLECTION_TYPES[:agencies],
        # {:include_image => true})
#         
      # @job[:a_name] = session[:agency].name if session[:agency]
      # @agency_contact = session[:person]
    # end
#     
    # if session[:user].user_type_id == Fs2User::USER_TYPES[:hiring_manager]
      # @company_contact = session[:person]
    # end
# 
    # add_field_binder("search_company-name", "search_company-id", 
        # "view_company_summary", FIELD_COLLECTION_TYPES[:companies],
        # {:include_image => true})
#         
    # @job[:c_name] = session[:company].name if session[:company]
    
    
    render 'maintain_job_profile.html', :layout => 'fs_layout_job_profile_edit'
    
       
  end
  
  
  def apply_for_job
    session[:user].update_attributes({:status_id => Fs2User::USER_STATUSES[:hit_apply_pre_registration]}) if session[:user].status_id < Fs2User::USER_STATUSES[:hit_apply_pre_registration]
    @upload_files = fetch_files(session[:person].id, [Fs2File::FILE_TYPES[:profile_photo], Fs2File::FILE_TYPES[:cv]], session[:person].anonymous)
    
    @job = fetch_job_profile(params[:job_id], session[:person].id)
    @fs_profiles = @job[:fs_profiles]
    set_active_fs_profile 
    
    render 'apply_for_job.html', :layout => 'fs_layout_job_apply'
  end
  
  def send_job_application
    
    if params[:cancel]
      redirect_to :action => :edit_job_seeker_profile, :controller => :fs_job_seeker, :job_seeker_id => session[:person].id
      return
    end
    
    is_registered = true
    is_registered = do_register_in_process if session[:user].status_id < Fs2User::USER_STATUSES[:registered]
    is_file_uploaded = upload_files({:upload_cv => session[:person].id}, true)
    
    # --- If no file was uploaded, look for existing ones
    @upload_files = fetch_files(session[:person].id, [Fs2File::FILE_TYPES[:profile_photo], Fs2File::FILE_TYPES[:cv]], session[:person].anonymous)
    
    # --- Not successful
    
    if !is_registered || (!is_file_uploaded && @upload_files[:cv].nil?)
      render 'apply_for_job.html', :layout => 'fs_layout_job_apply'
      
    # --- Successful
    else
      flash[:notice_hold] = "Successfully applied to job"
      session[:user].update_attributes({:status_id => Fs2User::USER_STATUSES[:applied_once]})
      
      is_email_sent = email_cv_to_recruiter(params[:job_id])
      
      redirect_to :action => :edit_job_seeker_profile, :controller => :fs_job_seeker, :job_seeker_id => session[:person].id
    end 
    
  end
  
  def ajax_save_job_fs_profile
    
    Fs2SkillsProfile.transaction do
          
      begin
        
        # return if session[:user].user_type_id == Fs2User::USER_TYPES[:job_seeker]
        
        @current_job = nil
        
        # --- CHECK IF THE JOB EXISTS (DETERMINE IF A NEW JOB SHOULD BE CREATED OR NOT)
        
        if params[:job_id] && !params[:job_id].blank?
          
          # --- FIND AN EXISTING JOB
          
          @current_job = Fs2Job.find_by_id(params[:job_id])
          
        end
          
          
        # --- CREATE A NEW JOB OBJECT
        
        if @current_job.nil?
          
          @current_job = Fs2Job.new({
            :title => "Leading Client Developer",
            :description => "Client-side: Javascript, HTML, CSS, AS3, Server-side; Java / .net / c++ / ruby, AJAX, JS internals, HTML 5, TDD, Open source projects, hacker, Java/Scala..."
          })
          raise 'ERROR' if !@current_job.valid?
          
          if session[:user].user_type_id == Fs2User::USER_TYPES[:recruitment_agent]
            @current_job.agency_contact_id = session[:person].id
          elsif session[:user].user_type_id == Fs2User::USER_TYPES[:hiring_manager]
            @current_job.company_contact_id = session[:person].id
          end
          
          @current_job.save(false)
          
          session[:jobs] = Hash.new if session[:jobs].nil?
          session[:jobs][:active_job_id] = @current_job.id
          # TODO: need to include the job's 'title' when saving the job summary into the 'session' object
          session[:jobs][@current_job.id] = nil
          
          
        # --- UPDATE AN EXISTING JOB OBJECT  
        
        else 
          
          puts " - UPDATING JOB: " + @current_job.id.to_s
          
        end
        
        
        # --- DELETE EXISTING FS_PROFILE
        
        job_fs_profiles = Fs2SkillsProfile.find(:all, :conditions => ["profile_type = ? AND entity_type = ? AND entity_id = ?", FS_PROFILE_TYPES[:user_profile], ENTITY_TYPES[:job], params[:job_id]]) if @current_job
        current_fs_profile = job_fs_profiles[0] if job_fs_profiles
        
        if current_fs_profile
          
          is_new_fs_profile = false
          
          # Call the 'delete' SQL function to be more efficient when calling the DB (Rails will perform 2-3 queries for each table when a 'destroy' or 'delete' occurs)
          Fs2SkillsProfilesMatch.connection.execute("delete from fs2_skills_profiles_matches where js_skills_profile_id = " + current_fs_profile.id.to_s)
          Fs2SkillsProfile.connection.execute("delete from fs2_skills_profiles where id = " + current_fs_profile.id.to_s)
          Fs2Skill.connection.execute("delete from fs2_skills where skills_profile_id = " + current_fs_profile.id.to_s)
          Fs2SkillDetail.connection.execute("delete from fs2_skill_details where skills_profile_id = " + current_fs_profile.id.to_s)
          Fs2AdditionalRequirement.connection.execute("delete from fs2_additional_requirements where skills_profile_id = " + current_fs_profile.id.to_s)
          
        end
        
        
        # --- CREATE NEW FS_PROFILE
        
        skills_profile = save_fs_profile({}, {
          :profile_type => FS_PROFILE_TYPES[:user_profile],
          :entity_type => ENTITY_TYPES[:job],
          :entity_id => @current_job.id})
          
        raise 'ERROR' if !skills_profile
        
        
        flash[:notice] = 'Job profile was created successfully!'
        flash[:error] = nil
         
         
        
        # ************************************************
        #  1 >  Run the search - make sure the latest information and match information is captured and stored
        # ************************************************
        
        # -------- The following will be based on reading matching information from session --------
        # search_entities(ENTITY_TYPES[:job_seeker], {:contact_details => true})
        @fs_results = search_entities_2({
            :request_fs_profile => @request_fs_profile
          }, {
            :entity_type => ENTITY_TYPES[:job_seeker],
            :include_contact_details => true
          })
        
        
        # ************************************************
        #  2 >  Save the matches (with status "NEW")
        # ************************************************
        
        # -------- The following will be based on reading matching information from session --------
        if @fs_results
          
          # ************************************************
          #  3 >  Get the 'job' files
          # ************************************************ 
          job_summary = {}
           
          if params[:send_emails]
            
            job_map_for_matches = fetch_job_profile(@current_job.id, nil, {:include_skills_profile => false})
            
            js_hash = {}
            
            
            job_summary[:files] = {}
            
            job_summary[:company_name] = job_map_for_matches[:company_obj].name
            job_summary[:agency_name] = job_map_for_matches[:agency_obj].name
            
            job_summary[:company_contact_user_id] = @job[:cu_id]
            job_summary[:company_contact_full_name] = @job[:cc_full_name]
            job_summary[:company_contact_user_email] = @job[:cu_email]
            job_summary[:agency_contact_user_id] = @job[:au_id]
            job_summary[:agency_contact_full_name] = @job[:ac_full_name]
            job_summary[:agency_contact_user_email] = @job[:au_email]
            
            if @upload_files[:agency_logo]
              job_summary[:files][:agency_logo] =  {
                :id => @upload_files[:agency_logo].id,
                :small_dimensions => @upload_files[:agency_logo].small_dimensions,
                :medium_dimensions => @upload_files[:agency_logo].medium_dimensions}
            end
            
            # Company logo
            if @upload_files[:company_logo]
              job_summary[:files][:company_logo] =  {
                :id => @upload_files[:company_logo].id,
                :small_dimensions => @upload_files[:company_logo].small_dimensions,
                :medium_dimensions => @upload_files[:company_logo].medium_dimensions}
            end
            
            transaction_h = {:email_type => Fs2Mailer::EMAIL_TYPES[:new_job_matches],
                :exchange_type => Fs2Mailer::EMAIL_EXCHANGE_TYPES[:system_to_job_seeker]}
            
          end
          
          @fs_results.each do |job_seeker|
            match = Fs2SkillsProfilesMatch.new
                  
            match.js_id = job_seeker[0]
            match.js_skills_profile_id = job_seeker[1][:skills_profile_id]
            match.js_match_status = 1 # new
            
            match.j_id = @current_job.id
            match.j_skills_profile_id = skills_profile.id
            match.j_match_status = 1 # new
            
            match.match_date = Time.now # new
            match.match_points = job_summary[:match_points] = job_seeker[1][:match_points]
            match.match_skills = job_summary[:matched_skills] = job_seeker[1][:matched_skills]
            match.match_skills_details = job_summary[:matched_skill_details] = job_seeker[1][:matched_skill_details]
            match.match_additional_requirements = job_summary[:matched_additional_requirements] = job_seeker[1][:matched_additional_requirements]
            
            if params[:send_emails]
              job_summary[:cv_trans_status_id] = job_seeker[1][:cv_trans_status_id]
              job_summary[:cv_trans_status_name] = job_seeker[1][:cv_trans_status_name]
              job_summary[:cv_trans_updated_at] = job_seeker[1][:cv_trans_updated_at]
              job_summary[:cv_trans_updated_at_formatted] = job_seeker[1][:cv_trans_updated_at_formatted]
              job_summary[:cv_trans_updated_at_time_ago] = job_seeker[1][:cv_trans_updated_at_time_ago]
            end
            
            match.save(false)
            
            if params[:send_emails]
            
              # *************************************************************************************
              #  3 >  Send JOB SEEKERS job match notifications -> email
              # *************************************************************************************

              metadata_params_h = {
                :recipients => [{
                  :id => job_seeker[1][:user_id].to_s, 
                  :email => job_seeker[1][:user_email], 
                  :name => job_seeker[1][:full_name]}]}
              
              next if metadata_params_h.nil?
              
              # Populate 'job_seeker' hash for 'hiring managers' and 'recruitment agents'
              js_hash["j_results_array"] = [[@current_job.id, job_summary]]
              
              # --->   Send 'job_seeker' details   <---
              # - - - - - - - - - - - - - - - - - - - - 
              send_message(metadata_params_h, js_hash, transaction_h)

            
              # **********************************************************
              #  4 >  Send JOB job seeker matches notifications -> email
              # **********************************************************
                  
              # ******************* JOB job seeker matches
              transaction_h[:email_type] = Fs2Mailer::EMAIL_TYPES[:new_job_seeker_matches] 
              
              if session[:user].user_type_id = Fs2User::USER_TYPES[:recruitment_agent]
                transaction_h[:exchange_type] = Fs2Mailer::EMAIL_EXCHANGE_TYPES[:system_to_recruitment_agent]
              elsif session[:user].user_type_id = Fs2User::USER_TYPES[:hiring_manager]
                transaction_h[:exchange_type] = Fs2Mailer::EMAIL_EXCHANGE_TYPES[:system_to_hiring_manager]
              end
              
              metadata_params_h = {
                :recipients => [{
                  :id => session[:user].id, 
                  :email => session[:user].email, 
                  :name => session[:person].full_name}]}
              
              send_message(
                metadata_params_h,
                {"js_results_array" => @fs_results},
                transaction_h)
                
            end
              
          end # iteration over search results
          
        end  
        
        @arr = {
            :status => "200",
            :action => "save_job_fs_profile",
            :message => "Successfully saved profile!",
            :job_id => @current_job.id
          }
        
      rescue Exception => exc
        
        # @job_seeker = @temp_job_seeker if @temp_job_seeker
        
        flash[:error] = 'Errors were found in the fields below, please check the messages next to each field'
        
        @arr = {
            :status => "101",
            :action => "save_job_fs_profile"
          }
                  
      end # rescue
    end # transaction
    
    respond_to do |format|
      
      format.json {  
        render :json => @arr.to_json, :callback => params[:callback] 
      }
      
    end
    
  end
  
  
  def __get_job_publishing_stats(job_id)
    
    sql = "select sum(case when b.status='Failed' THEN 1 ELSE 0 END) failed_or_pending, " + 
        "sum(case when b.status='Modified' THEN 1 ELSE 0 END) job_discussions, " + 
        "sum(case when b.status='Published' THEN 1 ELSE 0 END) published " + 
      "from " +
        "( " +
          "select a.id, a.user_id, a.job_id, a.publishing_channel_id, a.post_type, a.status, a.title, max(a.created_at) latest_change " + 
          "from " +
          "( " +
          "select * " + 
          "from fs2_job_publishing_posts " + 
          "where job_id = #{job_id.to_s} " +
          "group by publishing_channel_id, status " +
          ") a " +
          "group by a.publishing_channel_id " +
        ") b"
        
    publishing_stats = Fs2JobPublishingPost.find_by_sql(sql)
    publishing_stats[0].attributes
  end
  
  
  def __get_job_channel_stats(job_id)
    
    sql = "select a.id, a.user_id, a.job_id, a.publishing_channel_id, a.post_type, a.status, a.post_key, a.title, max(a.created_at) latest_change " + 
      "from " +
        "( " +
          "select * " + 
          "from fs2_job_publishing_posts " + 
          "where job_id = #{job_id.to_s} " +
          "group by publishing_channel_id, status " +
        ") a " +
      "group by a.publishing_channel_id"
        
    channel_stats = Fs2JobPublishingPost.find_by_sql(sql)
    channel_stats.collect { |row| row.attributes }
  end
  
  
  def __get_job_application_stats(job_profile)
    
    job_id = job_profile[:job_obj].id
    
    
    # -- 1 - Get the TOTAL UNIQUE VIEWS

    sql = "select count(b.id) total_unique_views " +
      "from " +
      "( " +
        "select a.id, a.agent, a.ip, b.id publishing_post_visitor_id, b.job_publishing_post_id, b.created_at, c.publishing_channel_id " +
        "from fs2_job_publishing_post_visitors b " +
          "join fs2_visitors a on (a.id = b.visitor_id) " +
          "left join fs2_job_publishing_posts c on (c.id = b.job_publishing_post_id) " +
        "where a.new_visitor = 1 " + 
          "and job_publishing_post_id in " + 
            "( " +
              "select id from fs2_job_publishing_posts " + 
              "where job_id = #{job_id.to_s} " +
                "and status in ('Published', 'Modified') " +
            ") " +
        "group by b.visitor_id " +
        "order by b.visitor_id desc, b.created_at desc " +
      ") b"
      
    total_unique_views__db = Fs2JobPublishingPostVisitor.find_by_sql(sql)
    total_unique_views = total_unique_views__db[0].attributes['total_unique_views']


    # -- 2 - Get the TOTAL UNIQUE APPLICATIONS
    
    fs_profiles = job_profile[:fs_profiles]
    fs_profiles_ids__array = fs_profiles.keys.delete_if{ |key| key == :info }
    
    job_applications__db = Fs2JobApplication.find(
      :all, 
      :conditions => ["job_fs_profile_id in (?)", fs_profiles_ids__array])
    total_unique_applications = job_applications__db.length
      
      
    {:total_unique_views => total_unique_views, :total_unique_applications => total_unique_applications}
  end
  
  # -- 
  #
  # Required fields:
  #  - params[:company] => { :name => XX }
  #  - params[:company_contact] => { :full_name => XX }
  #  - params[:upload_company_logo]
  #  - params[:agency] => { :name => XX }
  #  - params[:agency_contact] => { :full_name => XX }
  #  - params[:upload_agency_logo]
  #  
  # Assumptions:
  #  - All validations have already gone through, it's SAFE transactions
  def __save_job_profile(attributes)
    
    Fs2Job.transaction do
      
      begin
        
        params[:job_attributes] = Hash.new
        
        
        # -- X. Save the 'company' and the 'agency' objects
        
        company_profile = save_company_profile
        agency_profile = save_agency_profile
        
        
        # -- X. Save the 'job' object
        
        #TODO: Try and use the 'job' object created in the validation stage
        job = Fs2Job.new(params[:job_attributes])
        job.title = get_param(['job__title'])
        job.teaser = get_param(['job__teaser'])
        job.location = get_param(['job__location'])
        job.agency_contact_id = get_param(['recruiter_id']).to_i if get_param(["recruiting_company__type"]).to_i == Fs2Organisation::ORGANISATION_TYPES[:agency]
        job.company_contact_id = get_param(['recruiter_id']).to_i if get_param(["recruiting_company__type"]).to_i == Fs2Organisation::ORGANISATION_TYPES[:company]
        job.status_id = attributes[:status_id] # 'attributes' received from previous method
        job.save(false)
        
        
        # -- X. Save the fs_profile
        
        fs_profile = save_skills_profile({:job_id => job.id})
        
        
        # -- X. Save the logo
        
        if attributes[:company_logo] && get_param(['job_attributes', 'company_id'])
          attributes[:company_logo].entity_id = get_param(['job_attributes', 'company_id']).to_i
          attributes[:company_logo].entity_type_id = ENTITY_TYPES[:job]
          attributes[:company_logo].file_type = Fs2File::FILE_TYPES[:company_logo]
          attributes[:company_logo].save(false)
        end
        
        
        if attributes[:agency_logo] && get_param(['job_attributes', 'agency_id'])
          attributes[:agency_logo].entity_id = get_param(['job_attributes', 'agency_id']).to_i
          attributes[:agency_logo].entity_type_id = ENTITY_TYPES[:job]
          attributes[:agency_logo].file_type = Fs2File::FILE_TYPES[:agency_logo]
          attributes[:agency_logo].save(false)
        end
        
        return job
                    
          
      rescue Exception => exc
        
                  
      end # rescue
    end # transaction
      
  end      
  
  
  
  # -- 
  #
  # Required fields:
  #  - params[:company] => { :name => XX }
  #  - params[:company_contact] => { :full_name => XX }
  #  - params[:upload_company_logo]
  #  - params[:agency] => { :name => XX }
  #  - params[:agency_contact] => { :full_name => XX }
  #  - params[:upload_agency_logo]
  #  
  def save_job_profile
    
    respond_to do |format|
      
      #TODO:Add data fields check and ask to confirm after clicking 'cancel'
      if params[:cancel]
        
        format.html { redirect_to :action => :home, :controller => :five_skills }
          
      else
    
        Fs2Job.transaction do
          
          begin
            
            @job = {
              :j_id => nil,
              :c_name => get_param([:company, :name]),
              :a_name => get_param([:agency, :name]),
              :cc_full_name => get_param([:company_contact, :name]),
              :ac_full_name => get_param([:ageny_contact, :name])
            }
            
            params[:job_attributes] = Hash.new
            
            
            # -- X. Populate the 'job_attributes' hash
            
            raise 'ERROR' if !save_skills_profile
            company_profile = save_company_profile
            agency_profile = save_agency_profile
            
            # SAVE THE JOB
            # 1. Create a new job object and assign all relevant IDs
            job = Fs2Job.new(params[:job_attributes])
            raise 'ERROR' if !job.valid?
            
            # 7. Save
            job.skills_profile_id = @skills_profile.id
            job.save(false)
            
            session[:job] = job
            
            if (company_profile && company_profile[:company] && params[:upload_company_logo])
              curr_company_logo = Fs2File.find_by_entity_id_and_file_type(company_profile[:company].id, Fs2File::FILE_TYPES[:company_logo])
              Fs2File.destroy(curr_company_logo.id) if curr_company_logo
              upload_files({:upload_company_logo => company_profile[:company].id})
            end
            
            if (agency_profile && agency_profile[:agency] && params[:upload_agency_logo])
              curr_agency_logo = Fs2File.find_by_entity_id_and_file_type(agency_profile[:agency].id, Fs2File::FILE_TYPES[:agency_logo])
              Fs2File.destroy(curr_agency_logo.id) if curr_agency_logo
              upload_files({:upload_agency_logo => agency_profile[:agency].id})
            end            
            
            flash[:notice] = 'Job profile was created successfully!'
            flash[:error] = nil
  
            # Redirect back to the same page
            if params[:create_profile] # If chose to just update the form, return to the edit screen
              
              format.html { 
                redirect_to :action => :view_job_profile, 
                  :controller => :five_skills, 
                  :job_id => job.id }
                
            # This is an AJAX call
            elsif params[:save_as_template]
          
              add_skills_profile_binders("search_jobs", true)
              
#              prep_binders({
#                :field_name => "search_company-name", 
#                :field_id => "search_company-id", 
#                :ajax_call => "view_company_summary"})
#                
#              prep_binders({
#                :field_name => "search_agency-name", 
#                :field_id => "search_agency-id", 
#                :ajax_call => "view_agency_summary"}) 
              
              format.html { render 'maintain_job_profile.html', :layout => 'five_skills'  }
                
            end
            
          rescue Exception => exc
            
            flash[:error] = 'Errors were found in the fields below, please check the messages next to each field'
            
            puts " XXX: " + exc.message
            
            params[:show_hidden_fields] = true
            
            add_skills_profile_binders("search_jobs", true)
            
#            prep_binders({
#              :field_name => "search_company-name", 
#              :field_id => "search_company-id", 
#              :ajax_call => "view_company_summary"})
#              
#            prep_binders({
#              :field_name => "search_agency-name", 
#              :field_id => "search_agency-id", 
#              :ajax_call => "view_agency_summary"})
    
            format.html { render 'maintain_job_profile.html', :layout => 'five_skills'  }          
          end # rescue
        end # transaction
        
      end # else      
    end # respond_to
  end  
  
  def view_job_profile
    
    if !params[:job_id]
      flash[:error] = 'No "job_id" provided!'
      render 'view_job_profile.html', :layout => 'fs_layout_job_profile'
      return
    end

    # prep_job_profile(params[:job_id])
#     
    # # In case the logged-in user is a 'job seeker', make sure the 'matching' info is prepared
    # if session[:person] && session[:person].id && session[:user].user_type_id == Fs2User::USER_TYPES[:job_seeker]
#       
      # # Workaround to protect currently stored 'job' in session
      # tmp_job = session[:job] if session[:job]
#       
      # session[:job] = @job
      # prep_match_info(session[:person].id)
#       
      # # Workaround to protect currently stored 'job' in session
      # session[:job] = nil if !tmp_job
      # session[:job] = tmp_job if tmp_job
    # end  
    
    
    # --- If USER is a 'job_seeker'
    # Make sure to grab the 'job_seeker' details and perform a match
    if session[:user].user_type_id == Fs2User::USER_TYPES[:job_seeker]
      @job = fetch_job_profile(params[:job_id], session[:person].id)
    else
      @job = fetch_job_profile(params[:job_id], nil)  
    end
    
    @fs_profiles = @job[:fs_profiles]
    set_active_fs_profile
    
    render 'view_job_profile.html', :layout => 'fs_layout_job_profile'
  end  
  
  def edit_job_profile
    
    @job = fetch_job_profile(params[:job_id])
    @fs_profiles = @job[:fs_profiles]
    set_active_fs_profile
    
    add_ajax_start_up_actions("search_job_seekers")
    
    render 'maintain_job_profile.html', :layout => 'fs_layout_job_profile_edit'
  end
  
  def update_job_profile
    
    @current_job = session[:job]
    params[:job_attributes] = Hash.new
    
    respond_to do |format|
      
      #TODO:Add data fields check and ask to confirm after clicking 'cancel'
      if params[:cancel]
        
        format.html { redirect_to :action => :view_job_profile, 
          :controller => :five_skills,
          :job_id => params["job-id".to_sym]}
          
      else
    
        Fs2Job.transaction do
          
          begin
            
            @temp_job = Fs2Job.new(params[:job_attributes])
            raise 'ERROR' if !@temp_job.valid?
            
            # Update company and agency details
            company_profile = save_company_profile
            agency_profile = save_agency_profile
            
            # *************** IMPORT
            @current_skills_profile = Fs2SkillsProfile.find_by_id(@current_job.skills_profile_id)
            
            if @current_skills_profile
              js_sprofiles_match = Fs2SkillsProfilesMatch.find_by_j_skills_profile_id(@current_skills_profile.id)
              Fs2SkillsProfilesMatch.destroy_all(["js_skills_profile_id = ?", @current_skills_profile.id]) if js_sprofiles_match
              Fs2SkillsProfile.destroy(@current_skills_profile.id)
            end
            # *************************
            
            # ************ IMPORT
            skills_profile = save_skills_profile
            raise 'ERROR' if !skills_profile
            # *************************
             
            # Update 'job_seeker' details
            attributes_to_change = @current_job.attributes.merge(@temp_job.attributes) do |key, oldval, newval|
              if !newval.nil?; newval; else oldval; end
            end
            attributes_to_change[:skills_profile_id] = skills_profile.id
            @current_job.update_attributes(attributes_to_change)
            # *************************
            
            # 3. Upload files
            upload_files({:upload_company_logo => company_profile[:company].id}) if company_profile && company_profile[:company]
            upload_files({:upload_agency_logo => agency_profile[:agency].id}) if agency_profile && agency_profile[:agency]
            
            flash[:notice] = 'Job seeker profile was created successfully!'
            flash[:error] = nil
  
            # Redirect back to the same page
            if params[:update_profile] # If chose to just update the form, return to the edit screen
              
              # ************************************************
              #  1 >  Run the search
              # ************************************************
              search_entities(ENTITY_TYPES[:job_seeker], {:contact_details => true})
              
              # ************************************************
              #  2 >  Save the matches (with status "NEW")
              # ************************************************
              if @js_results_array
                
                # ************************************************
                #  3 >  Get the 'job' files
                # ************************************************ 
                
                prep_job_profile(@current_job.id, {:include_skills_profile => false})
                
                js_hash = {}
                
                job_summary = {}
                job_summary[:files] = {}
                
                job_summary[:company_name] = @job[:c_name]
                job_summary[:agency_name] = @job[:a_name]
                
                job_summary[:company_contact_user_id] = @job[:cu_id]
                job_summary[:company_contact_full_name] = @job[:cc_full_name]
                job_summary[:company_contact_user_email] = @job[:cu_email]
                job_summary[:agency_contact_user_id] = @job[:au_id]
                job_summary[:agency_contact_full_name] = @job[:ac_full_name]
                job_summary[:agency_contact_user_email] = @job[:au_email]
                
                if @upload_files[:agency_logo]
                  job_summary[:files][:agency_logo] =  {
                    :id => @upload_files[:agency_logo].id,
                    :small_dimensions => @upload_files[:agency_logo].small_dimensions,
                    :medium_dimensions => @upload_files[:agency_logo].medium_dimensions}
                end
                
                # Company logo
                if @upload_files[:company_logo]
                  job_summary[:files][:company_logo] =  {
                    :id => @upload_files[:company_logo].id,
                    :small_dimensions => @upload_files[:company_logo].small_dimensions,
                    :medium_dimensions => @upload_files[:company_logo].medium_dimensions}
                end
                
                transaction_h = {:email_type => Fs2Mailer::EMAIL_TYPES[:new_job_matches],
                    :exchange_type => Fs2Mailer::EMAIL_EXCHANGE_TYPES[:system_to_job_seeker]}
                
                @js_results_array.each do |job_seeker|
                  match = Fs2SkillsProfilesMatch.new
                  
                  match.js_id = job_seeker[0]
                  match.js_skills_profile_id = job_seeker[1][:skills_profile_id]
                  match.js_match_status = 1 # new
                  
                  match.j_id = session[:job].id
                  match.j_skills_profile_id = skills_profile.id
                  match.j_match_status = 1 # new
                  
                  match.match_date = Time.now # new
                  match.match_points = job_summary[:match_points] = job_seeker[1][:match_points]
                  match.match_skills = job_summary[:matched_skills] = job_seeker[1][:matched_skills]
                  match.match_skills_details = job_summary[:matched_skill_details] = job_seeker[1][:matched_skill_details]
                  match.match_additional_requirements = job_summary[:matched_additional_requirements] = job_seeker[1][:matched_additional_requirements]
                  
                  job_summary[:cv_trans_status_id] = job_seeker[1][:cv_trans_status_id]
                  job_summary[:cv_trans_status_name] = job_seeker[1][:cv_trans_status_name]
                  job_summary[:cv_trans_updated_at] = job_seeker[1][:cv_trans_updated_at]
                  job_summary[:cv_trans_updated_at_formatted] = job_seeker[1][:cv_trans_updated_at_formatted]
                  job_summary[:cv_trans_updated_at_time_ago] = job_seeker[1][:cv_trans_updated_at_time_ago]
                  
                  match.save(false)
                  
                  # *************************************************************************************
                  #  3 >  Send JOB SEEKERS job match notifications -> email
                  # *************************************************************************************

                  metadata_params_h = {
                    :recipients => [{
                      :id => job_seeker[1][:user_id].to_s, 
                      :email => job_seeker[1][:user_email], 
                      :name => job_seeker[1][:full_name]}]}
                  
                  next if metadata_params_h.nil?
                  
                  # Populate 'job_seeker' hash for 'hiring managers' and 'recruitment agents'
                  js_hash["j_results_array"] = [[@current_job.id, job_summary]]
                  
                  # --->   Send 'job_seeker' details   <---
                  # - - - - - - - - - - - - - - - - - - - - 
                  send_message(metadata_params_h, js_hash, transaction_h)
                end
                
                # **********************************************************
                #  4 >  Send JOB job seeker matches notifications -> email
                # **********************************************************
                    
                # ******************* JOB job seeker matches
                transaction_h[:email_type] = Fs2Mailer::EMAIL_TYPES[:new_job_seeker_matches] 
                
                if session[:user].user_type_id = Fs2User::USER_TYPES[:recruitment_agent]
                  transaction_h[:exchange_type] = Fs2Mailer::EMAIL_EXCHANGE_TYPES[:system_to_recruitment_agent]
                elsif session[:user].user_type_id = Fs2User::USER_TYPES[:hiring_manager]
                  transaction_h[:exchange_type] = Fs2Mailer::EMAIL_EXCHANGE_TYPES[:system_to_hiring_manager]
                end
                
                metadata_params_h = {
                  :recipients => [{
                    :id => session[:user].id, 
                    :email => session[:user].email, 
                    :name => session[:person].full_name}]}
                
                send_message(
                  metadata_params_h,
                  {"js_results_array" => @js_results_array},
                  transaction_h)
 
              end
              
              format.html { 
                redirect_to :action => :view_job_profile, 
                  :controller => :five_skills, 
                  :job_id => @current_job.id }
                
            # This is an AJAX call
            elsif params[:save_as_template]
              
              add_skills_profile_binders("search_jobs", true)
      
              format.html { render 'maintain_job_profile.html', :layout => 'five_skills'  }
                
            end
            
          rescue Exception => exc
            
            flash[:error] = 'Errors were found in the fields below, please check the messages next to each field'
            
            puts " XXX: " + exc.message
            
            add_skills_profile_binders("search_jobs", true)
              
            format.html { render 'maintain_job_profile.html', :layout => 'five_skills'  }          
          end # rescue
        end # transaction
        
      end # else      
    end # respond_to
  end
  
  def request_cv_from_job_seeker
    send_cv_emails(Fs2Mailer::EMAIL_TYPES[:cv_requested_for_job])
  end
  
  def view_job_seeker_matches
    prep_job_profile(session[:job].id)
    add_ajax_start_up_actions("search_job_seeker_matches")
    
    render 'view_job_seeker_matches.html', :layout => 'five_skills'
  end  
  
  def job_seekers_cv_delivery_log
    @job_seekers_trans = Fs2CvsToJobsTransaction.find(:all, :conditions => ["job_id = ?", session[:job].id.to_s], :order => "status_id ASC, updated_at DESC")
    @job_seekers_h = {} if @job_seekers_trans
    
    @job_seekers_trans.each do |job_seeker_trans|
      @upload_files = @skills_profile_matrix = nil
      
      prep_job_seeker_profile(job_seeker_trans.job_seeker_id)
      
      @job_seekers_h[job_seeker_trans.job_seeker_id] = @job_seeker
      @job_seekers_h[job_seeker_trans.job_seeker_id][:cv_trans_status_id] = job_seeker_trans.status_id
      @job_seekers_h[job_seeker_trans.job_seeker_id][:cv_trans_status_name] = job_seeker_trans.status_name
      @job_seekers_h[job_seeker_trans.job_seeker_id][:cv_trans_updated_at_formatted] = format_time(job_seeker_trans.updated_at.to_s) 
      @job_seekers_h[job_seeker_trans.job_seeker_id][:cv_trans_updated_at_time_ago] = format_time(job_seeker_trans.updated_at.to_s, TIME_FORMAT_TYPES[:time_ago])
      @job_seekers_h[job_seeker_trans.job_seeker_id][:skills_profile] = @skills_profile_matrix
      @job_seekers_h[job_seeker_trans.job_seeker_id][:files] = {}

      if @upload_files[:profile_photo]
        @job_seekers_h[job_seeker_trans.job_seeker_id][:files][:profile_photo] =  {
          :file_id => @upload_files[:profile_photo].id,
          :small_dimensions => @upload_files[:profile_photo].small_dimensions,
          :medium_dimensions => @upload_files[:profile_photo].medium_dimensions}
      end
      
      if @upload_files[:cv]
        @job_seekers_h[job_seeker_trans.job_seeker_id][:files][:cv] =  {:file_id => @upload_files[:cv].id}
      end 
    end
    
    render 'job_seekers_cv_delivery_log.html', :layout => 'five_skills'
  end        
  
end
