require 'image_size'
# require 'yaml'

class FsMvpController < FsBaseController
  
  # before_filter :set_defaults
  # before_filter :prep_page_view_mode,
    # :except => [:home, :download_file, :show_file, :view_template]
    
  before_filter :convert_json_to_hash
  before_filter :init_five_skills, 
    :except => [:home, :download_file, :show_file, :view_template]
  before_filter :init_mvp_params
  
  PAGE_VIEW_MODES = {:other => 0, :create => 1, :view => 2, :edit => 3}
  FORM_ACTIONS = {:create => "save", :save => "save", :edit => "update", :update => "update"}
  FORM_LABELS = {:create => "Create", :edit => "Edit"}
  FORM_UPDATE_LABELS = {:create => "Create", :save => "Create", :edit => "Update", :update => "Update"}
  ENTITY_TYPES = {:job => 1, :job_seeker => 2}
  
  def init_mvp_params
    @images_path = "http://" + request.env["HTTP_HOST"] + "/images/mvp/"
    
    session[:user_type_id] = 1 if !session[:user_type_id]
    session[:language] = 1 if !session[:language]
  end
  
  def set_defaults
    params[:default_search_ajax_call] = "search_job_seekers"
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
  
  def convert_json_to_hash
    return if !params[:json] || params[:json] == "null"
    
    params.merge!(ActiveSupport::JSON.decode(params[:json]))
    params.delete('json') 
  end
  
  # ***************************************
  #  GENERAL PAGES
  # ***************************************
  
  def home
    render 'home.html', :layout => 'five_skills'
  end
  
  # ***************************************
  #  FILTERS
  # ***************************************
  
  def init_five_skills
        
    # *************************
    #   A -> CONSTRUCT SKILLS KEYWORD MATRIX
    # *************************
    
    @skills_profile_matrix = {
      "skill_1" => {:name => "", :years_experience => "", :self_rate => "", :details => [""]},
      "skill_2" => {:name => "", :years_experience => "", :self_rate => "", :details => [""]},
      "skill_3" => {:name => "", :years_experience => "", :self_rate => "", :details => [""]},
      "skill_4" => {:name => "", :years_experience => "", :self_rate => "", :details => [""]},
      "skill_5" => {:name => "", :years_experience => "", :self_rate => "", :details => [""]}, 
      :additional_requirements => [""]}
      
    return if params['skills_profile'].nil?
    
    @skills_profile_keywords = Array.new(0)
    
    @skills_profile_ids_and_numbers = {
      "skill_1" => {:name => -1, :years_experience => -1, :self_rate => -1, :details => [-1]},
      "skill_2" => {:name => -1, :years_experience => -1, :self_rate => -1, :details => [-1]},
      "skill_3" => {:name => -1, :years_experience => -1, :self_rate => -1, :details => [-1]},
      "skill_4" => {:name => -1, :years_experience => -1, :self_rate => -1, :details => [-1]},
      "skill_5" => {:name => -1, :years_experience => -1, :self_rate => -1, :details => [-1]},
      :additional_requirements => [-1]}
    
    5.times do |i|
      
      @skill_key = "skill_" + (i+1).to_s
      
      if params['skills_profile'][@skill_key]
        
        # ----- Keyword matrix - Skill names
        if !params['skills_profile'][@skill_key][:name].blank?
          @skills_profile_matrix[@skill_key][:name] = params['skills_profile'][@skill_key][:name]
          @skills_profile_keywords.push(@skills_profile_matrix[@skill_key][:name])
        end
        
        # ----- Keyword matrix - Skill details
        if !params['skills_profile'][@skill_key][:details].blank?
          @skill_detail_keywords = params['skills_profile'][@skill_key][:details].to_s.split(",")
          @skill_detail_keywords.each_index do |keyword_index|
            
            if !@skill_detail_keywords[keyword_index].strip.blank?
              @skills_profile_matrix[@skill_key][:details][keyword_index] = @skill_detail_keywords[keyword_index].strip
              @skills_profile_keywords.push(@skills_profile_matrix[@skill_key][:details][keyword_index])  
            end
            
          end
        end
        
        @skills_profile_matrix[@skill_key][:years_experience] = params['skills_profile'][@skill_key][:years_experience]
        @skills_profile_matrix[@skill_key][:self_rate] = params['skills_profile'][@skill_key][:self_rate]
      end
    end
    
    # ----- Keyword matrix - Additional requirements
    if params['skills_profile'] && params['skills_profile']['additional_requirements']
      
      if !params['skills_profile']['additional_requirements'].blank?
        @additional_requirements_keywords = params['skills_profile']['additional_requirements'].split(",")
        @additional_requirements_keywords.each_index do |keyword_index|
          
          if !@additional_requirements_keywords[keyword_index].strip.blank?
            @skills_profile_matrix[:additional_requirements][keyword_index] = @additional_requirements_keywords[keyword_index].strip
            @skills_profile_keywords.push(@skills_profile_matrix[:additional_requirements][keyword_index])
          end
          
        end
      end
    end
    
    return if @skills_profile_keywords.length == 0
    
    
    # *************************
    #   B -> SEARCH KEYWORDS
    # *************************

    # -- 1 --  Construct a complete ',' separated list of all keywords that makes the current 5skills profile
#    @skills_profile_keywords.uniq!

    # Get the 'KEYWORD IDS' for the keyword names
    @keywords = Fs2Keyword.find_by_sql(
      "SELECT " + 
        "* " + 
      "FROM " + 
        "fs2_keywords " + 
      "WHERE " + 
        "keyword IN ('" + @skills_profile_keywords.join("','") + "')")
    
    # -- 3 --  Create a Hash that holds the 'EXISTING' keywords and their DB ID
    @existing_keywords_hash = Hash.new
    @keywords_hash = Hash.new
    @keywords.collect { |keyword| @existing_keywords_hash[keyword.keyword] = keyword.id }
    
    # -- 4 --  Complete the '@keywords_hash' hash with all keywords and their DB ID (create new IDs for new keywords)
    Fs2Keyword.transaction do
      begin
        @skills_profile_keywords.each do |keyword|
          
          if !keyword.blank?
            if @existing_keywords_hash[keyword]
              @current_keyword_id = @existing_keywords_hash[keyword]
            else
              @current_keyword = Fs2Keyword.new({:keyword => keyword})
              @current_keyword.save(false)
              @current_keyword_id = @current_keyword.id 
            end
      
            @keywords_hash[keyword] = @current_keyword_id
          end
          
        end                  
      rescue Exception => exc
        puts "*** ERROR: " + exc.message
      end # rescue
    end # transaction
    
    
    # *************************
    #   C -> CREATE DATABASE-READY SKILLS OBJECT STRUCTURE
    # *************************
    
    # Skill names
    @skills = Array.new
    @additional_requirements = Array.new
    
    5.times do |i|
      
      @skill_key = "skill_" + (i+1).to_s
      
      # Skill names
      if !@skills_profile_matrix[@skill_key][:name].blank?
        
        @skills[i] = Fs2Skill.new
        @skills[i].years_experience = @skills_profile_matrix[@skill_key][:years_experience].to_i
        @skills[i].self_rate = @skills_profile_matrix[@skill_key][:self_rate].to_i
        @skills[i].priority = i + 1
        @skills[i].keyword_id = @keywords_hash[@skills_profile_matrix[@skill_key][:name]]
        
        @skills_profile_ids_and_numbers[@skill_key][:name] = @skills[i].keyword_id
        @skills_profile_ids_and_numbers[@skill_key][:years_experience] = @skills[i].years_experience
        
        # Skill details
        if !@skills_profile_matrix[@skill_key][:details][0].blank?
          @skills_profile_matrix[@skill_key][:details].each_index do |keyword_index|
            
            @current_detail_keyword = @skills_profile_matrix[@skill_key][:details][keyword_index]
            @skills_profile_ids_and_numbers[@skill_key][:details][keyword_index] = @keywords_hash[@current_detail_keyword] 
    
            if @current_detail_keyword && !@current_detail_keyword.blank?
              @skills[i].skill_details.build(:attributes => {
                :priority => keyword_index + 1,
                :keyword_id => @keywords_hash[@current_detail_keyword]})
            end
            
          end
        end
      end
    end
    
    if !@skills_profile_matrix[:additional_requirements][0].blank?
      
      # 3. Create the 'additional requirements' object
      @skills_profile_matrix[:additional_requirements].each_index do |keyword_index|
        
        @skills_profile_ids_and_numbers[:additional_requirements][keyword_index] = 
          @keywords_hash[@skills_profile_matrix[:additional_requirements][keyword_index]]
        
        @additional_requirements[keyword_index] = Fs2AdditionalRequirement.new
        @additional_requirements[keyword_index].priority = keyword_index + 1
        @additional_requirements[keyword_index].keyword_id = 
          @keywords_hash[@skills_profile_matrix[:additional_requirements][keyword_index]]

      end
    end
    
  end
  
  # ***************************************
  #  MVP - Start
  # ***************************************
  
  def mvp_s_test
    # @user_files = FlycFile.find_all_by_person_id(session[:user].id)
    
    @errors = {}
    @arr = {}
    user_type_id = Fs2User::USER_TYPES[:job_seeker] 
    
    #### USER / EMAIL
    ####
    @user = Fs2User.new({
      :email => get_param([:user_login, :email]),
      :status_id => Fs2User::USER_STATUSES[:mvp_lead],
      :user_type_id => user_type_id})
    
    @errors[:user_login] = @user.errors if !@user.valid? && @user.errors
    
    #### CV
    ####
    @file_form = FlycFile.new(params[:cv])
    # @file_form.person_id = session[:user].id
    @errors[:cv] = @file_form.errors if !@file_form.valid? && @file_form.errors
    
    Fs2User.transaction do
      
      begin
          
        if @errors.empty?
          
          #### USER / EMAIL
          ####
          if user_type_id == 4 # recruiter
            @person = Fs2Contact.new
            @person.contact_type = 4
            
            job = Fs2Job.new

            @arr[:action] = "MVP_s_r_i_want_in"
            user_role_name = "Recruiter"
            exchange_type = 2            
          elsif user_type_id == Fs2User::USER_TYPES[:job_seeker]
            @person = Fs2JobSeeker.new
            
            @arr[:action] = "MVP_s_js_i_want_in"
            user_role_name = "Job seeker"
            exchange_type = 1
          end
      
          @user.save(false)
          @person.user_id = @user.id
          @person.save(false)
          
          @arr[:status] = "200"
          
          # Send email
          #
          # :email_type = 
          #  1 -> new lead registered on site
          # :exchange_type =
          #  1 -> system to job seeker
          #  2 -> system to recruiter
          #
          transaction_h = {:email_type => 1, :exchange_type => exchange_type}
              
          metadata_params_h = {
              :recipients => [{
                :email => @user.email,
                :name => user_role_name}]}
            
          send_s_message(metadata_params_h, nil, transaction_h)
          
          
          #### CV
          ####
          @file_form.save(false)
          
          
          #### WRAP UP - SUCCESS
          flash[:notice_hold] = 'Successfully uploaded the file.'
          redirect_to :action => :mvp_s_js_thanks, :controller => :fs_mvp
          
        else
          
          @arr[:status] = "101"
          @arr[:message] = "Errors were found in the fields below, please check the messages next to each field"
          @arr[:errors] = {}
          
          # Iterate over 'fields' Hash
          @errors.each do |fld_name, fld_obj|
            @arr[:errors][fld_name.to_sym] = {}
            
            # Iterate over field 'attributes'
            fld_obj.each do |fld_atr, fld_val|
              @arr[:errors][fld_name.to_sym][fld_atr] = [] if @arr[:errors][fld_name.to_sym][fld_atr].nil?
              @arr[:errors][fld_name.to_sym][fld_atr].push(fld_val)
              
            end
          end
          
          @server_response = @arr.to_json
          
          raise "ERROR!"
          
        end
      
      rescue => e
        puts 'Upload failed. ' + e.to_s
        flash[:error] = 'Upload failed. Please try again.'
        
        # Delete the file
        @file_form.delete if @file_form
        
        respond_to do |format|
          format.html { render 'home_s_job_seeker_EN.html', :layout => 'mvp_s' }
        end
      end
    end
  end
  
  def mvp_s_job_seeker_EN
    session[:user_type_id] = 1
    
    if session[:language] && session[:language] == 2 && !request.env["PATH_INFO"].end_with?('/en')
      render 'home_s_job_seeker_HE.html', :layout => 'mvp_s'
    else
      session[:language] = 1
      render 'home_s_job_seeker_EN.html', :layout => 'mvp_s'
    end
    
  end
  
  def mvp_s_recruiter_EN
    session[:user_type_id] = 4
    
    if session[:language] && session[:language] == 2 && !request.env["PATH_INFO"].end_with?('/en')
      render 'home_s_recruiter_HE.html', :layout => 'mvp_s'
    else
      session[:language] = 1
      render 'home_s_recruiter_EN.html', :layout => 'mvp_s'
    end
  end
  
  def mvp_s_job_seeker_HE
    session[:user_type_id] = 1
    session[:language] = 2
    render 'home_s_job_seeker_HE.html', :layout => 'mvp_s'
  end
  
  def mvp_s_recruiter_HE
    session[:user_type_id] = 4
    session[:language] = 2
    render 'home_s_recruiter_HE.html', :layout => 'mvp_s'
  end
  
  def mvp_s_js_i_want_in
    mvp_s_register(Fs2User::USER_TYPES[:job_seeker]) 
  end
  
  def mvp_s_r_i_want_in
    mvp_s_register(4) 
  end
  
  def mvp_s_register(user_type_id)
    @skills = session[:skills]
    failed_validation = false
    job = nil
    
    #
    # 1. VALIDATION
    #
    @user = Fs2User.new({
      :email => get_param([:user_login, :email]),
      :status_id => Fs2User::USER_STATUSES[:mvp_lead],
      :user_type_id => user_type_id})
      
    failed_validation = true if !@user.valid?
    
    if user_type_id == 4 # recruiter
                        
      @person = Fs2Contact.new
      @person.contact_type = 4
      
      job = Fs2Job.new
            
    elsif user_type_id == Fs2User::USER_TYPES[:job_seeker]
          
      @person = Fs2JobSeeker.new
          
    end
      
    #
    # 2. SAVING
    #
    Fs2User.transaction do
      
      @errors = {}
      @arr = {}
      user_role_name = ""
      exchange_type = nil
      
      if user_type_id == 4
        
        @arr[:action] = "MVP_s_r_i_want_in"
        user_role_name = "Recruiter"
        exchange_type = 2
        
      elsif user_type_id == Fs2User::USER_TYPES[:job_seeker]
        
        @arr[:action] = "MVP_s_js_i_want_in"
        user_role_name = "Job seeker"
        exchange_type = 1
        
      end
        
      begin
        
        if !failed_validation    
        
          @user.save(false)
          @person.user_id = @user.id
          @person.save(false)
          
          @arr[:status] = "200"
          
          # Send email
          #
          # :email_type = 
          #  1 -> new lead registered on site
          # :exchange_type =
          #  1 -> system to job seeker
          #  2 -> system to recruiter
          #
          transaction_h = {:email_type => 1, :exchange_type => exchange_type}
              
          metadata_params_h = {
              :recipients => [{
                :email => @user.email,
                :name => user_role_name}]}
            
          send_s_message(metadata_params_h, nil, transaction_h)
          
        else
          
          @errors[:user_login] = @user.errors if @user.errors
          @arr[:status] = "101"
          @arr[:message] = "Errors were found in the fields below, please check the messages next to each field"
          
          # Iterate over 'fields' Hash
          @errors.each do |fld_name, fld_obj|
            @arr[:errors] = {fld_name.to_sym => {}}
            
            # Iterate over field 'attributes'
            fld_obj.each do |fld_atr, fld_val|
              @arr[:errors][fld_name.to_sym][fld_atr] = [] if @arr[:errors][fld_name.to_sym][fld_atr].nil?
              @arr[:errors][fld_name.to_sym][fld_atr].push(fld_val)
              
            end
          end
          
        end
      
      rescue Exception => exc
        
        ## Revert the 'hashed' password to 'normal string' password for continuity-sake
        @arr[:status] = "99"
        @arr[:message] = "Unknown error occured: " + exc.message
        
      end # rescue
    end # transaction
    
    respond_to do |format|
      format.json { render :json => @arr.to_json, :callback => params[:callback] }
    end 
    
  end 
  
  def mvp_s_js_thanks
    
    if session[:language] && session[:language] == 1
      render 'thanks_s_job_seeker_EN.html', :layout => 'mvp_s'
    elsif session[:language] && session[:language] == 2
      render 'thanks_s_job_seeker_HE.html', :layout => 'mvp_s'
    end
    
  end
  
  def mvp_s_r_thanks
    
    if session[:language] && session[:language] == 1
       render 'thanks_s_recruiter_EN.html', :layout => 'mvp_s'
    elsif session[:language] && session[:language] == 2
       render 'thanks_s_recruiter_HE.html', :layout => 'mvp_s'
    end
   
  end
  
  
    
  def mvp
    redirect_to :action => :mvp_job_seeker, :controller => :fs_mvp
  end
  
  def mvp_init_totals
    sql = "select hm.hm_count, ra.ra_count, js.js_count from " + 
      "(select count(id) hm_count from fs2_users where status_id = 5 and user_type_id = " + Fs2User::USER_TYPES[:hiring_manager].to_s + ") hm, " + 
      "(select count(id) ra_count from fs2_users where status_id = 5 and user_type_id = " + Fs2User::USER_TYPES[:recruitment_agent].to_s + ") ra, " + 
      "(select count(id) js_count from fs2_users where status_id = 5 and user_type_id = " + Fs2User::USER_TYPES[:job_seeker].to_s + ") js"
      
    @counters = Fs2User.find_by_sql(sql)
    
    @counters = @counters[0] if @counters
  end
  
  def mvp_job_seeker    
    mvp_init_totals
    
    add_field_binder("skill_1-name", nil, "MVP_search_jobs", FIELD_COLLECTION_TYPES[:keywords])
    add_field_binder("skill_2-name", nil, "MVP_search_jobs", FIELD_COLLECTION_TYPES[:keywords])
        
    render 'home_job_seeker.html', :layout => 'mvp'
  end
  
  def mvp_recruitment_agent
    mvp_init_totals
    
    add_field_binder("skill_1-name", nil, "MVP_search_job_seekers", FIELD_COLLECTION_TYPES[:keywords])
    add_field_binder("skill_2-name", nil, "MVP_search_job_seekers", FIELD_COLLECTION_TYPES[:keywords])
        
    render 'home_recruitment_agent.html', :layout => 'mvp'
  end
  
  def mvp_hiring_manager
    mvp_init_totals
    
    add_field_binder("skill_1-name", nil, "MVP_search_job_seekers", FIELD_COLLECTION_TYPES[:keywords])
    add_field_binder("skill_2-name", nil, "MVP_search_job_seekers", FIELD_COLLECTION_TYPES[:keywords])
        
    render 'home_hiring_manager.html', :layout => 'mvp'
  end
  
  def mvp_search_jobs
    r_count = mvp_search_entities(ENTITY_TYPES[:job])
    
    respond_to do |format|
      
      format.json {
        @arr = {
            :status => "200",
            :action => "MVP_search_jobs",
            :count => r_count
          }
          
        render :json => @arr.to_json, :callback => params[:callback] 
      }
      
    end
  end
  
  def mvp_search_job_seekers
    r_count = mvp_search_entities(ENTITY_TYPES[:job_seeker])
    
    respond_to do |format|
      
      format.json {
        @arr = {
            :status => "200",
            :action => "MVP_search_job_seekers",
            :count => r_count
          }
          
        render :json => @arr.to_json, :callback => params[:callback] 
      }
      
    end
  end
  
  def mvp_search_entities(i_entity_type)
    
    if @keywords_hash
      
      #                                                 #
      # ----------- PERFORMING SEARCH ----------- START #
      #                                                 #
      @keywords_ids = @keywords_hash.values.join(",")
      @results_entities = nil
      
      sql = "select "
      
      if i_entity_type == ENTITY_TYPES[:job_seeker]
        sql += "count(js.id) r_count "
      elsif i_entity_type == ENTITY_TYPES[:job]
        sql += "count(j.id) r_count "
      end
         
      sql += "from "
        
      if i_entity_type == ENTITY_TYPES[:job_seeker]
        
        sql += 
          "fs2_job_seekers js JOIN " +
          "fs2_skills_profiles sp on (js.id = sp.job_seeker_id) JOIN "
          
      elsif i_entity_type == ENTITY_TYPES[:job]
        
        sql += 
          "fs2_jobs j JOIN " + 
          "fs2_skills_profiles sp on (j.skills_profile_id = sp.id) JOIN "
          
      end
         
      sql += "fs2_skills s on (sp.id = s.skills_profile_id) "
      sql += "where "
      
      if i_entity_type == ENTITY_TYPES[:job_seeker]
        sql += "js.id IS NOT NULL AND "
      elsif i_entity_type == ENTITY_TYPES[:job]
        sql += "j.id IS NOT NULL AND "
      end
     
      sql += 
         "s.keyword_id in (" + @keywords_ids + ")"
         
      if i_entity_type == ENTITY_TYPES[:job_seeker]
        @results_entities = Fs2JobSeeker.find_by_sql(sql)
      elsif i_entity_type == ENTITY_TYPES[:job]
        @results_entities = Fs2Job.find_by_sql(sql)
      end
      #                                               #
      # ----------- PERFORMING SEARCH ----------- END #
      #                                               #
      
      
      return if @results_entities.nil?
      
      return @results_entities[0][:r_count]
      
    
    end # if @keywords_hash exists
    
  end
  
  def mvp_find_jobs
    
    # Store skills_profile information in session
    session[:skills] = @skills
    
    respond_to do |format|
      format.json {
      
        if @error
      
          @arr = {
            :status => "101",
            :action => "MVP_find_jobs",
            :message => "Errors were found in the fields below, please check the messages next to each field"
          }
          
        else
          
          @arr = {
            :status => "200",
            :action => "MVP_find_jobs"
          }
          
        end
      
        render :json => @arr.to_json, :callback => params[:callback]
      }
    end   
  end  
  
  def mvp_find_job_seekers
    session[:skills] = @skills
    
    respond_to do |format|
      format.json {
      
        if @error
      
          @arr = {
            :status => "101",
            :action => "MVP_find_job_seekers",
            :message => "Errors were found in the fields below, please check the messages next to each field"
          }
          
        else
          
          @arr = {
            :status => "200",
            :action => "MVP_find_job_seekers"
          }
          
        end
      
        render :json => @arr.to_json, :callback => params[:callback]
      }
    end   
  end 
  
  def mvp_js_i_want_in
    mvp_register(Fs2User::USER_TYPES[:job_seeker]) 
  end
  
  def mvp_ra_i_want_in
    mvp_register(Fs2User::USER_TYPES[:recruitment_agent]) 
  end 
  
  def mvp_hm_i_want_in
    mvp_register(Fs2User::USER_TYPES[:hiring_manager])
  end
  
  def mvp_start_over
    session[:mvp_completed] = nil
    cookies[:mvp_completed] = nil
    
    redirect_to :action => :mvp, :controller => :fs_mvp

  end 
  
  def mvp_register(user_type_id)
    @skills = session[:skills]
    failed_validation = false
    job = nil
    
    #
    # 1. VALIDATION
    #
    @user = Fs2User.new({
      :email => get_param([:user_login, :email]),
      :status_id => Fs2User::USER_STATUSES[:mvp_lead],
      :user_type_id => user_type_id})
      
    failed_validation = true if !@user.valid?
    
    if user_type_id == Fs2User::USER_TYPES[:recruitment_agent] || user_type_id == Fs2User::USER_TYPES[:hiring_manager]
                        
      @person = Fs2Contact.new
      @person.contact_type = Fs2Contact::CONTACT_TYPES[:agency] if user_type_id == Fs2User::USER_TYPES[:recruitment_agent]
      @person.contact_type = Fs2Contact::CONTACT_TYPES[:company] if user_type_id == Fs2User::USER_TYPES[:hiring_manager]
      
      job = Fs2Job.new
            
    elsif user_type_id == Fs2User::USER_TYPES[:job_seeker]
          
      @person = Fs2JobSeeker.new
          
    end
      
    #
    # 2. SAVING
    #
    Fs2User.transaction do
      
      @errors = {}
        
      begin
        
        if !failed_validation    
        
          @user.save(false)
          @person.user_id = @user.id
          @person.save(false)
          
          if user_type_id == Fs2User::USER_TYPES[:recruitment_agent] || user_type_id == Fs2User::USER_TYPES[:hiring_manager]
            save_skills_profile
            
            if @skills_profile
              job.skills_profile_id = @skills_profile.id
              job.save(false)  
            end
            
          elsif user_type_id == Fs2User::USER_TYPES[:job_seeker]
            save_skills_profile({:job_seeker_id => @person.id})
          end
          
          # set the cookie and session information
          session[:mvp_completed] = true
          cookies[:mvp_completed] = true
          
          @arr = {
            :status => "200",
            :action => "MVP_i_want_in"
          }
          
        else
          
          @errors[:user_login] = @user.errors if @user.errors
          
          @arr = {
            :status => "101",
            :action => "MVP_i_want_in",
            :message => "Errors were found in the fields below, please check the messages next to each field" 
          }
          
          # Iterate over 'fields' Hash
          @errors.each do |fld_name, fld_obj|
            @arr[:errors] = {fld_name.to_sym => {}}
            
            # Iterate over field 'attributes'
            fld_obj.each do |fld_atr, fld_val|
              @arr[:errors][fld_name.to_sym][fld_atr] = [] if @arr[:errors][fld_name.to_sym][fld_atr].nil?
              @arr[:errors][fld_name.to_sym][fld_atr].push(fld_val)
              
            end
          end
          
        end
      
      rescue Exception => exc
        
        ## Revert the 'hashed' password to 'normal string' password for continuity-sake
        @arr = {
          :status => "99",
          :action => "MVP_i_want_in",
          :message => "Unknown error occured: " + exc.message 
        }
        
      end # rescue
    end # transaction
    
    respond_to do |format|
      format.json { render :json => @arr.to_json, :callback => params[:callback] }
    end 
    
  end 
  
  # ***************************************
  #  MVP - End
  # ***************************************
  
  def create_template
    
    Fs2Template.transaction do
          
      begin
        
        # -----------------------
        # 1. Save the 'template' object & the 'skills_profile' object
        # -----------------------
        @skills_template = Fs2Template.new(:name => params[:template_name])
        @skills_profile = Fs2SkillsProfile.new

        raise 'ERROR' if !@skills_template.valid?
        raise 'ERROR' if !@skills_profile.valid?
        
        @skills_profile.save(false)
        
        @skills_template.skills_profile_id = @skills_profile.id
        @skills_template.save(false)
        
        # -----------------------
        # 2. Set the 'skills_profile' id in the entire 5skills data structure
        # -----------------------
        @skills.each do |skill|
          skill.skills_profile_id = @skills_profile.id
          
          skill.skill_details.each do |skill_details|
            skill_details.skills_profile_id = @skills_profile.id
          end
          
          skill.save(false)
        end
        
        # -----------------------
        # 3. Set the 'skills_profile' id in the 'additional_requirements' objects 
        # -----------------------
        @additional_requirements.each do |additional_requirement|
          additional_requirement.skills_profile_id = @skills_profile.id
          
          additional_requirement.save(false)
        end
        
      rescue Exception => exc
        
        puts " XXX: " + exc.message
        @error = true
        
      end # rescue
    end # transaction


    respond_to do |format|
      format.json {
      
        if @error
      
          @arr = {
            :status => "101",
            :action => "create_template",
            :message => "Errors were found in the fields below, please check the messages next to each field"
          }
          
        else
          
          @arr = {
            :status => "200",
            :action => "create_template",
            :message => "Created new template!"
          }
          
        end
      
        render :json => @arr.to_json, :callback => params[:callback]
      }
    end
    
  end
  
  def view_template
    prep_skills_profile({:template_id => params[:template_id]})
    
    respond_to do |format|
      format.json {
      
        if @error
      
          @arr = {
            :status => "101",
            :action => "view_template",
            :message => "Errors were found in the fields below, please check the messages next to each field"
          }
          
        else
          
          @arr = {
            :status => "200",
            :action => "view_template",
            :skills_profile_matrix => @skills_profile_matrix
          }
          
        end
      
        render :json => @arr.to_json, :callback => params[:callback]
      }
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
  
  # ***************************************
  #  JOB SEEKER
  # ***************************************
  
  def find_job_seekers
    respond_to do |format|
    
      format.html {
        add_skills_profile_binders("search_job_seekers", true)
        
        render 'find_job_seekers.html', :layout => 'five_skills'
      }
      
    end
    
  end
  
  def add_skills_profile_binders(s_search_ajax_action, b_include_template_field = false)
    # 1. Add the 5 skills binders
    5.times do |i|
      add_field_binder("skill_" + (i+1).to_s + "-name", nil, s_search_ajax_action, FIELD_COLLECTION_TYPES[:keywords])
      add_field_binder("skill_" + (i+1).to_s + "-details", nil, 
        s_search_ajax_action, FIELD_COLLECTION_TYPES[:keywords], 
        {:comma_suffix => true})
    end
    
    # 2. Add the 'additional_requirements' field binder
    add_field_binder("additional_requirements", nil, 
      s_search_ajax_action, FIELD_COLLECTION_TYPES[:keywords], 
      {:comma_suffix => true})
    
    # 3. Add the 'template' field binder
    add_field_binder("search_template-name", "search_template-id", "view_template_and_search", FIELD_COLLECTION_TYPES[:templates]) if b_include_template_field
    
    # 4. Add the sorting field binder - set the default search action
    params[:default_search_ajax_call] = s_search_ajax_action
  end
  
  def search_job_seekers
    search_entities(ENTITY_TYPES[:job_seeker])
    
    respond_to do |format|
      
      format.json {
        @arr = {
            :status => "200",
            :action => params[:action],
            :results => @js_results_array
          }
          
        render :json => @arr.to_json, :callback => params[:callback] 
      }
      
    end    
  end
  
  def search_jobs
    search_entities(ENTITY_TYPES[:job])
    
    respond_to do |format|
      
      format.json {
        @arr = {
            :status => "200",
            :action => params[:action],
            :results => @js_results_array
          }
          
        render :json => @arr.to_json, :callback => params[:callback] 
      }
      
    end    
  end
  
  #
  # Main 5skills search method / algorithm
  #
  def search_entities(i_entity_type, extra_fields = {})
    
    if @keywords_hash
      
      #                                                 #
      # ----------- PERFORMING SEARCH ----------- START #
      #                                                 #
      @keywords_ids = @keywords_hash.values.join(",")
      @results_entities = nil
      
      sql = "select "
      
      if i_entity_type == ENTITY_TYPES[:job_seeker]
        
        sql += 
          "js.id, js.full_name, js.anonymous js_anonymous, js.looking_for_work js_looking_for_work, " + 
          "f.id f_id, f.file_type f_ft, f.small_dimensions f_sd, f.medium_dimensions f_md, "
          
        if extra_fields[:contact_details] && extra_fields[:contact_details] == true
          sql += 
            "js_user.id js_user_id, js_user.email js_user_email, "
        end
          
      elsif i_entity_type == ENTITY_TYPES[:job]
        
        sql += 
          "j.id, " + 
          "j_comp.name j_comp_name, " + 
          "j_agen.name j_agen_name, " +
          "j_comp_f.id j_comp_logo_id, j_comp_f.file_type j_comp_logo_ft, j_comp_f.small_dimensions j_comp_logo_sd, j_comp_f.medium_dimensions j_comp_logo_md, " + 
          "j_agen_f.id j_agen_logo_id, j_agen_f.file_type j_agen_logo_ft, j_agen_f.small_dimensions j_agen_logo_sd, j_agen_f.medium_dimensions j_agen_logo_md, "
          
          if extra_fields[:contact_details] && extra_fields[:contact_details] == true
            sql += 
              "j_comp_user.id j_comp_user_id, j_comp_contact.full_name j_comp_contact_full_name, j_comp_user.email j_comp_user_email, " +
              "j_agen_user.id j_agen_user_id, j_agen_contact.full_name j_agen_contact_full_name, j_agen_user.email j_agen_user_email, "
          end
      end
         
      sql += 
         "sp.id sp_id, sp.display_matrix sp_display_matrix, " + 
         "s.keyword_id s_kid, s.priority sp, s.years_experience, s.self_rate, " + 
         "sd.keyword_id sd_kid, sd.priority sdp, " + 
         "ar.keyword_id ar_kid, ar.priority arp, " +
         "ctjt.status_id cv_trans_status_id, ctjt.updated_at cv_trans_updated_at " + 
        "from "
        
      if i_entity_type == ENTITY_TYPES[:job_seeker]
        
        sql += 
          "fs2_job_seekers js JOIN " +
          "fs2_skills_profiles sp on (js.id = sp.job_seeker_id) JOIN "
          
      elsif i_entity_type == ENTITY_TYPES[:job]
        
        sql += 
          "fs2_jobs j JOIN " + 
          "fs2_skills_profiles sp on (j.skills_profile_id = sp.id) JOIN "
          
      end
         
      sql += 
         "fs2_skills s on (sp.id = s.skills_profile_id) LEFT JOIN " + 
         "fs2_skill_details sd on (s.id = sd.skill_id) LEFT JOIN " + 
         "fs2_additional_requirements ar on (sp.id = ar.skills_profile_id) LEFT JOIN "
         
      if i_entity_type == ENTITY_TYPES[:job_seeker]
        
        sql += 
          "fs2_files f on (js.id = f.entity_id) LEFT JOIN " + 
          "(select a.* from fs2_cvs_to_jobs_transactions a where a.job_id = " + session[:job].id.to_s + ") ctjt on (js.id = ctjt.job_seeker_id) "
          
          if extra_fields[:contact_details] && extra_fields[:contact_details] == true
            
            sql +=
              "LEFT JOIN " +
              "fs2_users js_user on (js.user_id = js_user.id) "
              
          end
        
      elsif i_entity_type == ENTITY_TYPES[:job]
        sql +=
          "fs2_organisations j_comp on (j.company_id = j_comp.id) LEFT JOIN " + 
          "fs2_files j_comp_f on (j.company_id = j_comp_f.entity_id) LEFT JOIN " + 
          "fs2_organisations j_agen on (j.agency_id = j_agen.id) LEFT JOIN " + 
          "fs2_files j_agen_f on (j.agency_id = j_agen_f.entity_id) LEFT JOIN " +
          "(select a.* from fs2_cvs_to_jobs_transactions a where a.job_seeker_id = " + session[:person].id.to_s + ") ctjt on (j.id = ctjt.job_id) "
          
        if extra_fields[:contact_details] && extra_fields[:contact_details] == true
          
          sql +=
            "LEFT JOIN " +
            "fs2_contacts j_comp_contact on (j.company_contact_id = j_comp_contact.id) LEFT JOIN " +
            "fs2_contacts j_agen_contact on (j.agency_contact_id = j_agen_contact.id) LEFT JOIN " +
            "fs2_users j_comp_user on (j_comp_contact.user_id = j_comp_user.id) LEFT JOIN " +
            "fs2_users j_agen_user on (j_agen_contact.user_id = j_agen_user.id) "
            
        end
      end
         
      sql += "where "
      
      if i_entity_type == ENTITY_TYPES[:job_seeker]
        sql += "js.id IS NOT NULL AND ("
      elsif i_entity_type == ENTITY_TYPES[:job]
        sql += "j.id IS NOT NULL AND ("
      end
     
      sql += 
         "s.keyword_id in (" + @keywords_ids + ") OR " +
         "sd.keyword_id in (" + @keywords_ids + ") OR " + 
         "ar.keyword_id in (" + @keywords_ids + ")) " + 
        "order by " + 
         "id asc"
         
      if i_entity_type == ENTITY_TYPES[:job_seeker]
        @results_entities = Fs2JobSeeker.find_by_sql(sql)
      elsif i_entity_type == ENTITY_TYPES[:job]
        @results_entities = Fs2Job.find_by_sql(sql)
      end
      #                                               #
      # ----------- PERFORMING SEARCH ----------- END #
      #                                               #
      
      
      return if @results_entities.nil?
      
      
      search_entities_create_results(i_entity_type, extra_fields)
      
    
    end # if @keywords_hash exists
    
  end
  
  def search_entities_create_results(i_entity_type, extra_fields)
    @previous_job_seeker = nil
    @js_skills_matrix = Hash.new
    @js_profiles = Hash.new
    
    @results_entities.each do |entity|
      
      js_id = entity.id.to_i
      js_skill_priority = entity.sp.to_i
      js_skill_detail_priority = entity.sdp.to_i if !entity.sdp.nil?
      js_additional_requirements_priority = entity.arp.to_i if !entity.arp.nil?
      
      # If this is the 1st record or the start of a new entity record
      if !@previous_entity_id || entity.id != @previous_entity_id
        
        @js_skills_matrix[js_id] = {
          1 => {:name => -1, :years_experience => -1, :self_rate => -1, :details => nil},
          2 => {:name => -1, :years_experience => -1, :self_rate => -1, :details => nil},
          3 => {:name => -1, :years_experience => -1, :self_rate => -1, :details => nil},
          4 => {:name => -1, :years_experience => -1, :self_rate => -1, :details => nil},
          5 => {:name => -1, :years_experience => -1, :self_rate => -1, :details => nil},
          :additional_requirements => nil}
        
        if @js_profiles[js_id].nil?
          
          # '@js_profiles' is used to hold information for display
          # => ':match_points', 'matched_...' fields will holds the 'text' information for display
          @js_profiles[js_id] = {
            :skills_profile_id => entity.sp_id.to_i,
            :files => Hash.new,
            :match_points => 0,
            :matched_skills => Array.new(0),
            :matched_experience_n_rate => Array.new(0),
            :matched_skill_details => Array.new(0),
            :matched_additional_requirements => Array.new(0)}
          
          # Populate the 'display_matrix' Array if it exists
          @js_profiles[js_id][:skill_display_matrix] = YAML::load(entity.sp_display_matrix) if entity.sp_display_matrix 
          
          # Populate '@js_profiles' with the 'status', 'full_name', 'email', 'update date/time'
          search_entities_populate_entity_values(js_id, entity, i_entity_type, extra_fields)
          
        end

      end
        
      # Populate '@js_skills_matrix' with the 'keyword_id's
      # => 'search_entities_perform_matches_pct' needs the skills_ids to perform the matching
      search_entities_populate_keyword_ids(js_id, js_skill_priority, js_skill_detail_priority, js_additional_requirements_priority, entity)
      
      # Populate '@js_profiles' with the relevant files
      search_entities_populate_entity_files(js_id, entity, i_entity_type)
      
      @previous_entity_id = js_id
      
    end
    
    
    search_entities_perform_matches_pct(i_entity_type)
    # search_entities_perform_matches
    
    
    search_entities_sort_matches_pct
    # search_entities_sort_matches
    
  end
  
  # Populate the following information:
  # => Status information
  # => updated date/time information
  # => full_name of the job_seeker or contact
  # => email address
  #
  def search_entities_populate_entity_values(js_id, entity, i_entity_type, extra_fields)
      
    # Populate the 'status' information
    if entity.cv_trans_status_id
      @js_profiles[js_id][:cv_trans_status_id] = entity.cv_trans_status_id
      @js_profiles[js_id][:cv_trans_status_name] = Fs2CvsToJobsTransaction::get_status_name(entity.cv_trans_status_id)
    end
    
    # Populate the 'updated_at' information
    if entity.cv_trans_updated_at
      @js_profiles[js_id][:cv_trans_updated_at] = entity.cv_trans_updated_at
      @js_profiles[js_id][:cv_trans_updated_at_formatted] = format_time(entity.cv_trans_updated_at)
      @js_profiles[js_id][:cv_trans_updated_at_time_ago] = format_time(entity.cv_trans_updated_at, TIME_FORMAT_TYPES[:time_ago])
    end
      
    # Update the 'full_name' and 'email' information of the job_seeker or contacts
    if i_entity_type == ENTITY_TYPES[:job_seeker]
      
      @js_profiles[js_id][:full_name] = entity.full_name
      @js_profiles[js_id][:anonymous] = entity.js_anonymous
      @js_profiles[js_id][:looking_for_work] = entity.js_looking_for_work
      
      if extra_fields[:contact_details] && extra_fields[:contact_details] == true
        @js_profiles[js_id][:user_id] = entity.js_user_id
        @js_profiles[js_id][:user_email] = entity.js_user_email
      end
      
    elsif i_entity_type == ENTITY_TYPES[:job]
      
      @js_profiles[js_id][:company_name] = entity.j_comp_name
      @js_profiles[js_id][:agency_name] = entity.j_agen_name
      
      if extra_fields[:contact_details] && extra_fields[:contact_details] == true
        @js_profiles[js_id][:company_contact_user_id] = entity.j_comp_user_id
        @js_profiles[js_id][:company_contact_full_name] = entity.j_comp_contact_full_name
        @js_profiles[js_id][:company_contact_user_email] = entity.j_comp_user_email
        @js_profiles[js_id][:agency_contact_user_id] = entity.j_agen_user_id
        @js_profiles[js_id][:agency_contact_full_name] = entity.j_agen_contact_full_name
        @js_profiles[js_id][:agency_contact_user_email] = entity.j_agen_user_email
      end
      
    end
  end
  
  def search_entities_populate_entity_files(js_id, entity, i_entity_type)
    #                                     #
    # ----------- FILES ----------- START #
    #                                     #
    if i_entity_type == ENTITY_TYPES[:job_seeker]
      
      if entity.js_anonymous.to_i == 1
        
        @js_profiles[js_id][:files][Fs2File::FILE_TYPES.index(entity.f_ft.to_i)] = 
          {:id => session[:defaults][:anonymous_profile_photo_file].id, 
          :small_dimensions => session[:defaults][:anonymous_profile_photo_file].small_dimensions,
          :medium_dimensions => session[:defaults][:anonymous_profile_photo_file].medium_dimensions}
        
      elsif !entity.f_id.nil?
        
        @js_profiles[js_id][:files][Fs2File::FILE_TYPES.index(entity.f_ft.to_i)] = 
          {:id => entity.f_id, 
          :small_dimensions => entity.f_sd,
          :medium_dimensions => entity.f_md}
          
      end
      
    elsif i_entity_type == ENTITY_TYPES[:job]
      
      if !entity.j_comp_logo_id.nil?
        @js_profiles[js_id][:files][Fs2File::FILE_TYPES.index(entity.j_comp_logo_ft.to_i)] = 
          {:id => entity.j_comp_logo_id, 
          :small_dimensions => entity.j_comp_logo_sd,
          :medium_dimensions => entity.j_comp_logo_md}
      end
      
      if !entity.j_agen_logo_id.nil?
        @js_profiles[js_id][:files][Fs2File::FILE_TYPES.index(entity.j_agen_logo_ft.to_i)] = 
          {:id => entity.j_agen_logo_id, 
          :small_dimensions => entity.j_agen_logo_sd,
          :medium_dimensions => entity.j_agen_logo_md}
      end
      
    end
    #                                   #
    # ----------- FILES ----------- END #
    #   
  end
  
  # Populate '@js_skills_matrix' with keyword ids
  #
  def search_entities_populate_keyword_ids(js_id, js_skill_priority, js_skill_detail_priority, js_additional_requirements_priority, entity)
    if @js_skills_matrix[js_id][js_skill_priority][:name] == -1 
      @js_skills_matrix[js_id][js_skill_priority][:name] = entity.s_kid.to_i
      @js_skills_matrix[js_id][js_skill_priority][:years_experience] = entity.years_experience.to_i
      @js_skills_matrix[js_id][js_skill_priority][:self_rate] = entity.self_rate.to_i  
    end
    
    if !@js_skills_matrix[js_id][js_skill_priority][:details]
      @js_skills_matrix[js_id][js_skill_priority][:details] = Hash.new
    end
    
    # ASSUMPTION: Duplicates are consistent, don't need to check if a value already exists, just override
    if !js_skill_detail_priority.nil? && !entity.sd_kid.nil?
      @js_skills_matrix[js_id][js_skill_priority][:details][js_skill_detail_priority] = entity.sd_kid.to_i
    end
    
    if !@js_skills_matrix[js_id][:additional_requirements] 
      @js_skills_matrix[js_id][:additional_requirements] = Hash.new
    end
    
    # ASSUMPTION: Duplicates are consistent, don't need to check if a value already exists, just override
    if !js_additional_requirements_priority.nil? && !entity.ar_kid.nil?
      @js_skills_matrix[js_id][:additional_requirements][js_additional_requirements_priority] = entity.ar_kid.to_i
    end
  end
  
  def search_entities_sort_matches_pct
    # 7) Sort the search results by the 'matched_points' descending
    # *********************************************************************************
    @js_results_array = @js_profiles.sort {|a, b| b[1][:match_pct] <=> a[1][:match_pct]} 
  end
  
  def search_entities_sort_matches
    # 6) Sort the 'inner' matched arrays. Matched arrays are the arrays containing the matched keywords
    #    for each cell in the 'skills_profile' profile, i.e.:
    #    "matched_skills", "matched_skills_details", "matched_additional_requirements"
    # *********************************************************************************
    @js_profiles.each do |js_id, js_profile|
      js_profile[:matched_skills] = js_profile[:matched_skills].sort {|a, b| a <=> b}.join(",")
      
      if !js_profile[:matched_skills].blank? && js_profile[:matched_experience_n_rate].length > 0
        js_profile[:matched_skills] += " (" + js_profile[:matched_experience_n_rate].join(",") + ")"
      end
      
      js_profile[:matched_skill_details] = js_profile[:matched_skill_details].sort {|a, b| a <=> b}.join(",")
      js_profile[:matched_additional_requirements] = 
        js_profile[:matched_additional_requirements].sort {|a, b| a <=> b}.join(",")
    end
    
    # 7) Sort the search results by the 'matched_points' descending
    # *********************************************************************************
    @js_results_array = @js_profiles.sort {|a, b| b[1][:match_points] <=> a[1][:match_points]} 
  end
  
  def match(search_cell_range, result_cell_range, search_obj, result_obj)
    
    # Set the SEARCH cells
    search_matrix = Array.new
    result_matrix = Array.new
    
    5.times do |i|
      req_skill_key = "skill_" + (i + 1).to_s
      res_skill_key = i + 1
      
      search_matrix[i] = Array.new
      search_matrix[i][0] = search_obj[req_skill_key][:name]
      search_matrix[i][1] = search_obj[req_skill_key][:years_experience]
      search_matrix[i][2] = search_obj[req_skill_key][:details] # 'details' is already an array
      
      result_matrix[i] = Array.new
      result_matrix[i][0] = result_obj[res_skill_key][:name]
      result_matrix[i][1] = result_obj[res_skill_key][:years_experience]
      result_matrix[i][2] = result_obj[res_skill_key][:details] # 'details' is already an array
        
    end
    
    # Run the SEARCH
    matched_cells = {:search => nil, :result => nil}
    
    search_cell_range.each do |search_cell|
      
      result_cell_range.each do |result_cell|
      
        if search_matrix[search_cell[0]][search_cell[1]] == result_matrix[result_cell[0]][result_cell[1]]
          matched_cells[:search] = search_cell
          matched_cells[:result] = result_cell
        end
          
      end
      
    end
    
    matched_cells
    
  end
  
  def search_entities_perform_matches_pct(i_entity_type)
    # Define the basline direction (for matching minimum years experience criteria)
    baseline = 0 # left side = search = is baseline
    
    case i_entity_type
      when ENTITY_TYPES[:job_seeker] # Searching for job seekers, '0' is the baseline (the job requirements) = left hand-side
        baseline = 0
      when ENTITY_TYPES[:job] # Searching for jobs, the 'job' is the baseline, i.e. 1 = right hand-side
        baseline = 1
    end
    
    # The keyword counter
    fs_search_criteria = @skills_profile_ids_and_numbers
    
    # Hash holding the match objects
    matches_h = {}
    
    @js_skills_matrix.each do |entity_id, fs_result_record|

      # 'fs_result_record' has the 'details' object. This object is a Hash where 'key -> Priority, value -> keyword id'      
      matches_h[entity_id] = Fs2Match.new(fs_search_criteria, fs_result_record, baseline)
      matches_h[entity_id].match
      
      @js_profiles[entity_id][:skill_matches_matrix] = matches_h[entity_id].result_matrix
      @js_profiles[entity_id][:match_pct] = matches_h[entity_id].pct
      
      # Update the 'results' object
      if @js_profiles[entity_id][:skill_display_matrix].nil? 
        case i_entity_type
          when ENTITY_TYPES[:job_seeker] # Searching for job seekers, '0' is the baseline (the job requirements) = left hand-side
            prep_skills_profile({:job_seeker_id => entity_id})
          when ENTITY_TYPES[:job] # Searching for jobs, the 'job' is the baseline, i.e. 1 = right hand-side
            prep_skills_profile({:job_id => entity_id})
        end
        
        @js_profiles[entity_id][:skill_display_matrix] = []
        
        5.times do |row|
        
          req_skill_key = "skill_" + (row + 1).to_s
          @js_profiles[entity_id][:skill_display_matrix][row] = Array.new
          
          @js_profiles[entity_id][:skill_display_matrix][row][0] = @skills_profile_matrix[req_skill_key][:name]
          @js_profiles[entity_id][:skill_display_matrix][row][1] = @skills_profile_matrix[req_skill_key][:years_experience]
          @js_profiles[entity_id][:skill_display_matrix][row][2] = @skills_profile_matrix[req_skill_key][:details]
          
        end
        
        # Add the 'result_matrix' to the DB
        fs_profile = Fs2SkillsProfile.find_by_id(@js_profiles[entity_id][:skills_profile_id])        
        fs_profile.update_attributes({:display_matrix => @js_profiles[entity_id][:skill_display_matrix]}) if fs_profile
        
      end
            
      puts " XXXX MATCH: " + matches_h[entity_id].pct.to_s
            
    end
    
    puts "STOP"
  end
  
  def search_entities_perform_matches
    #                                                          #
    # ----------- MATCH AND CALCULATE POINTS ----------- START #
    #                                                          #
    
    # 1. Iterate over search results (it provides the 'general-matching' of keywords)
    #  - The results provide the 'position' of the matched skills in the results
    #  - Just need to match it them to the position in the searched skills
    
    # ******** Iterate over the 'keyword_hash' and create a 'mapping' map:
    #
    # SYNTAX:
    #
    #   MAX TOTAL Points PER KEYWORD ==> 240
    #     1 => 20 + 15 + 10 + 5 = 50
    #     2 => 19 + 14 + 9 + 4 = 46
    #     3 => 18 + 13 + 8 + 3 = 42
    #     4 => 17 + 12 + 7 + 2 = 38
    #     5 => 16 + 11 + 6 + 1 = 34
    #     additional_requirements => 30
    #
    # --- CURRENTLY ACTIVE!! ---
    #   MAX TOTAL Points PER KEYWORD ==> 325
    #     1 => 25 + 24 + 23 + 22 = 94
    #     2 => 20 + 19 + 18 + 17 = 74
    #     3 => 15 + 14 + 13 + 12 = 54
    #     4 => 10 + 9 + 8 + 7 = 34
    #     5 => 5 + 4 + 3 + 2 = 14
    #     additional_requirements => 55
    
    # 1) Define the points matrix (value of each 'cell' in the skills_profile matrix)
    # *********************************************************************************
    @keyword_matching_points = {
        1 => {:name => 25, :years_experience => 24, :self_rate => 23, :details => 22},
        2 => {:name => 20, :years_experience => 19, :self_rate => 18, :details => 17},
        3 => {:name => 15, :years_experience => 14, :self_rate => 13, :details => 12},
        4 => {:name => 10, :years_experience => 9, :self_rate => 8, :details => 7},
        5 => {:name => 5, :years_experience => 4, :self_rate => 3, :details => 2},
        :additional_requirements => 55}
    
    # The keyword counter
    request = @skills_profile_ids_and_numbers
    
    # 2) Iterate over all 'keywords' and try to find a match in the REQUEST and RESPONSE entities
    #
    #    The REQEUST holds the 'search criteria' 'skills' keyword ID's and 'years_experience' numbers
    #     - The '@skills_profile_ids_and_numbers' is populated from the 'init_five_skills' method
    #       which is invoked as a 'before_filter' on most requests
    #
    #    The RESPONSE holds the 'skills' keyword ID's and 'years_experience' numbers for each search result
    # *********************************************************************************
    @keywords_hash.each do |keyword, keyword_id|
    
      # 3) Iterate over all 'found' entities' keyword ID's.
      #    This collection contains all the keyword ID's of the found skills_profiles
      # *********************************************************************************
      @js_skills_matrix.each do |js_id, response|
      
        @keyword_points_count = 0
      
        5.times do |i|
          req_skill_key = "skill_" + (i + 1).to_s
          res_skill_key = i + 1
          
          # 4) Add REQUEST points
          # *********************************************************************************
          if request[req_skill_key][:name] == keyword_id
            @keyword_points_count += @keyword_matching_points[res_skill_key][:name]
          end
          
          if request[req_skill_key][:details] && request[req_skill_key][:details].include?(keyword_id)
            @keyword_points_count += @keyword_matching_points[res_skill_key][:details]
          end
          
          if request[:additional_requirements] && request[:additional_requirements].include?(keyword_id)
            @keyword_points_count += @keyword_matching_points[:additional_requirements]
          end
          
          # 5) Add RESPONSE points
          # *********************************************************************************
          if response[res_skill_key][:name] == keyword_id
            # First, grab the skill name for displaying the search results
            @js_profiles[js_id][:matched_skills].push(res_skill_key.to_s + " - " + 
              @keywords_hash.index(response[res_skill_key][:name]))
            
            # First, add the skill match points
            @keyword_points_count += @keyword_matching_points[res_skill_key][:name]
            
            # EXACT MATCH Check
            if response[res_skill_key][:name] == request[req_skill_key][:name]
              @keyword_points_count += @keyword_matching_points[res_skill_key][:name]
            end
            
            # Now check years experience, self rate and details
            if request[req_skill_key][:years_experience] != -1 &&
                response[res_skill_key][:years_experience] >= request[req_skill_key][:years_experience]
              @js_profiles[js_id][:matched_experience_n_rate].push(response[res_skill_key][:years_experience])
              @keyword_points_count += @keyword_matching_points[res_skill_key][:years_experience]
            end
            
            if request[req_skill_key][:self_rate] != -1 && 
                response[res_skill_key][:self_rate] >= request[req_skill_key][:self_rate]
              @js_profiles[js_id][:matched_experience_n_rate].push(response[res_skill_key][:self_rate])
              @keyword_points_count += @keyword_matching_points[res_skill_key][:self_rate]
            end
            
          end # if response[res_skill_key][:name] == keyword_id
          
          if response[res_skill_key][:details]
            response[res_skill_key][:details].each do |details_priority, details_keyword_id|
              # If there was a match on details
              if details_keyword_id == keyword_id
                @js_profiles[js_id][:matched_skill_details].push(
                  res_skill_key.to_s + " - " + @keywords_hash.index(details_keyword_id))
                @keyword_points_count += @keyword_matching_points[res_skill_key][:details]
              end
            
              # EXACT MATCH Check
              if request[req_skill_key][:details].include?(details_keyword_id)
                @keyword_points_count += @keyword_matching_points[res_skill_key][:details]
              end
            end
          end
          
        end # 5.times loop (the skills)
        
        if @js_skills_matrix[:additional_requirements]
          @js_skills_matrix[:additional_requirements].each do |additional_req_priority, additional_req_keyword_id|
            # If there was a match on additional requirements
            if additional_req_keyword_id == keyword_id
              @js_profiles[js_id][:matched_additional_requirements].push(
                res_skill_key.to_s + " - " + @keywords_hash.index(additional_req_keyword_id))
              @keyword_points_count += @keyword_matching_points[:additional_requirements]
            end
          
            # EXACT MATCH Check
            if request[:additional_requirements].include?(additional_req_keyword_id)
              @keyword_points_count += @keyword_matching_points[:additional_requirements]
            end
          end
        end # [:additional_rqeuirements]
        
      # Update the points
      @js_profiles[js_id][:match_points] += @keyword_points_count
        
      end # '@js_skills_matrix' iteration (iterate over all 'job seekers')
      
    end # '@keywords_hash' iteration (iterate over all 'keywords')
  end
  
  
  
  def list

#    keywords_per_page = 10
#
#    sort = case params['sort']
#             when "name"  then "name"
#             when "qty"   then "quantity"
#             when "price" then "price"
#             when "name_reverse"  then "name DESC"
#             when "qty_reverse"   then "quantity DESC"
#             when "price_reverse" then "price DESC"
#           end

    conditions = ["keyword LIKE ?", "%#{params[:query]}%"] unless params[:query].nil?

    @total = Fs2Keyword.count(:conditions => conditions)
#    @keywords_pages, @keywords = paginate :keywords, :order => sort, :conditions => conditions, :per_page => keywords_per_page

    @keywords = Fs2Keyword.find(:all, :conditions => conditions)

    if request.xml_http_request?
      render :partial => "items_list", :layout => false
    end

  end
  
  def prep_files(entity_id, a_file_types, is_anonymous = false)
    is_anonymous = false if is_anonymous.nil?
    
    @files = Fs2File.find(:all, 
      :conditions => ["entity_id = ? AND file_type IN (?)", entity_id, a_file_types],
      :order => "file_type ASC, updated_at ASC")
    
    if @files
      @upload_files = Hash.new if @upload_files.nil?
      
      @files.each do |file|
        
        if is_anonymous == true && file.file_type == Fs2File::FILE_TYPES[:profile_photo]
          @upload_files[file.file_type_name] = session[:defaults][:anonymous_profile_photo_file]
        elsif !file.file_type_name.nil?
          @upload_files[file.file_type_name] = file
        end
        
      end
    end
  end
  
  def prep_job_seeker_profile(job_seeker_id, flags = {:include_skills_profile => true})
    @job_seeker = Fs2JobSeeker.find_by_id(job_seeker_id)
    @job_seeker_user = Fs2User.find_by_id(@job_seeker.user_id) if @job_seeker.user_id
    
    prep_skills_profile({:job_seeker_id => @job_seeker.id}) if flags && flags[:include_skills_profile] && flags[:include_skills_profile] == true
    prep_files(@job_seeker.id, [Fs2File::FILE_TYPES[:profile_photo], Fs2File::FILE_TYPES[:cv]], @job_seeker.anonymous)
  end
  
  def prep_job_profile(job_id, flags = {:include_skills_profile => true})
    sql = "select " +
     "j.id j_id, " + 
     "c.id c_id, c.name c_name, " +  
     "cu.id cu_id, cu.email cu_email, cc.full_name cc_full_name, " + 
     "a.id a_id, a.name a_name, " + 
     "au.id au_id, au.email au_email, ac.full_name ac_full_name " +
    "from " +
     "fs2_jobs j left join " +
     "fs2_organisations c on (j.company_id = c.id) left join " +
     "fs2_organisations a on (j.agency_id = a.id) left join " +
     "fs2_contacts cc on (j.company_contact_id = cc.id) left join " +
     "fs2_contacts ac on (j.agency_contact_id = ac.id) left join " +
     "fs2_users cu on (cc.user_id = cu.id) left join " +
     "fs2_users au on (ac.user_id = au.id) " +
    "where " +
     "j.id = " + job_id.to_s
    
    jobs = Fs2Job.find_by_sql(sql)
    @job = clean_attributes(jobs[0]) if jobs && jobs[0]
    
    if session[:user].user_type_id == Fs2User::USER_TYPES[:recruitment_agent]
      @agency_contact = session[:person]
    elsif session[:user].user_type_id == Fs2User::USER_TYPES[:hiring_manager]
      @company_contact = session[:person]
    end

    if @job
      prep_skills_profile({:job_id => @job[:j_id]}) if flags && flags[:include_skills_profile] && flags[:include_skills_profile] == true 
      prep_files(@job[:c_id], [Fs2File::FILE_TYPES[:company_logo]])
      prep_files(@job[:a_id], [Fs2File::FILE_TYPES[:agency_logo]])
    end
  end
  
  def edit_job_profile
    
    add_skills_profile_binders("search_job_seekers", true)
    prep_job_profile(params[:job_id])
    add_ajax_start_up_actions("search_job_seekers")
    
    if session[:user].user_type_id == Fs2User::USER_TYPES[:recruitment_agent]
      add_field_binder("search_agency-name", "search_agency-id", 
        "view_agency_summary", FIELD_COLLECTION_TYPES[:agencies],
        {:include_image => true})
        
      @agency_contact = session[:person]
    end

    add_field_binder("search_company-name", "search_company-id", 
        "view_company_summary", FIELD_COLLECTION_TYPES[:companies],
        {:include_image => true})
    
    render 'maintain_job_profile.html', :layout => 'five_skills'
  end
  
  def clean_attributes(fs_object = nil)
    return if fs_object.nil?
    
    h_attributes = Hash.new
    fs_object.attributes.each {|attribute| h_attributes[attribute[0].to_sym] = fs_object[attribute[0]].to_s}
    
    h_attributes
  end
  
  def view_job_matches
    prep_job_seeker_profile(session[:person].id)
    add_ajax_start_up_actions("search_job_matches")
    
    render 'view_job_matches.html', :layout => 'five_skills'
  end
    
  def manage_job_seeker_settings

  end
  
  def view_job_seeker_matches
    prep_job_profile(session[:job].id)
    add_ajax_start_up_actions("search_job_seeker_matches")
    
    render 'view_job_seeker_matches.html', :layout => 'five_skills'
  end
  
  def manage_job_settings
  end
  
  def update_job_settings
  end
  
  def edit_job_seeker_profile
    add_skills_profile_binders("search_jobs", true)
    prep_job_seeker_profile(params[:job_seeker_id])
    add_ajax_start_up_actions("search_jobs")
    
    render 'maintain_job_seeker_profile.html', :layout => 'five_skills'
  end
  
  def create_job_profile
    @upload_files = Hash.new
    @job = {
      :j_id => nil,
      :c_name => "",
      :a_name => "",
      :cc_full_name => "",
      :ac_full_name => ""
    }
    
    add_skills_profile_binders("search_jobs", true)

    if session[:user].user_type_id == Fs2User::USER_TYPES[:recruitment_agent]
      add_field_binder("search_agency-name", "search_agency-id", 
        "view_agency_summary", FIELD_COLLECTION_TYPES[:agencies],
        {:include_image => true})
        
      @job[:a_name] = session[:agency].name if session[:agency]
      @agency_contact = session[:person]
    end
    
    if session[:user].user_type_id == Fs2User::USER_TYPES[:hiring_manager]
      @company_contact = session[:person]
    end

    add_field_binder("search_company-name", "search_company-id", 
        "view_company_summary", FIELD_COLLECTION_TYPES[:companies],
        {:include_image => true})
        
    @job[:c_name] = session[:company].name if session[:company]
    
    render 'maintain_job_profile.html', :layout => 'five_skills'
  end
  
  def create_job_seeker_profile
    add_skills_profile_binders("search_job_seekers", true)
    
    @job_seeker = session[:person]
    
    render 'maintain_job_seeker_profile.html', :layout => 'five_skills'
  end
  
  #
  # 'h_fields' => 
  #   {'upload_company_logo' => [company's DB organisation id],
  #   'upload_agency_logo' => [agency's DB organisation id]}
  #
  def upload_files(h_fields, is_destory_previous = false)
    @upload_files = Hash.new if @upload_files.nil?
    
    begin
      
        Fs2File.transaction do
          
          h_fields.each do |key, value|
            next if params[key].nil?
            
            Fs2File.destroy(value.to_i) if is_destroy_previous == true
            
            file_type_sym = key.to_s.sub(/(upload_)/, '').to_sym
            
            @upload_files[file_type_sym] = Fs2File.new(params[key])
            @upload_files[file_type_sym].entity_id = value.to_i
            @upload_files[file_type_sym].file_type = Fs2File::FILE_TYPES[file_type_sym]
            
            if @upload_files[file_type_sym].is_image
              @upload_files[file_type_sym].original_dimensions = ImageSize.path(@upload_files[file_type_sym].path).size.join("x")
              @upload_files[file_type_sym].small_dimensions = @upload_files[file_type_sym].resize_from_s(Fs2File::IMAGE_JOB_SEEKER_PLACEHOLDER_SIZES[:small])
              @upload_files[file_type_sym].medium_dimensions = @upload_files[file_type_sym].resize_from_s(Fs2File::IMAGE_JOB_SEEKER_PLACEHOLDER_SIZES[:medium])
              @upload_files[file_type_sym].large_dimensions = @upload_files[file_type_sym].resize_from_s(Fs2File::IMAGE_JOB_SEEKER_PLACEHOLDER_SIZES[:large])
            end
            
            raise 'ERRORS: ' + @upload_files[file_type_sym].errors.to_xml if !@upload_files[file_type_sym].valid?\
            
            # Save the new file information
            @upload_files[file_type_sym].save(false)
          end
          
        end
    
      rescue => e
        puts 'Upload failed. ' + e.to_s
        flash[:error] = 'Upload failed. Please try again.'
        
        # Delete the files
        if @upload_files
          @upload_files.each do |file_key, file_obj|
            file_obj.delete
          end
        end
        
        raise 'ERRORS: Upload failed. ' + e.to_s
      end
  end
  
#  def upload_files(entity_id)
#    @upload_files = Hash.new
#    
#    begin
#      
#        Fs2File.transaction do
#          
#          params.each_key do |key|
#            if key.include? "upload" 
#              file_type_sym = key.sub(/(upload_)/, '').to_sym
#              
#              @upload_files[file_type_sym] = Fs2File.new(params[key.to_sym])
#              @upload_files[file_type_sym].entity_id = entity_id
#              @upload_files[file_type_sym].file_type = Fs2File::FILE_TYPES[file_type_sym]
#              
#              if @upload_files[file_type_sym].is_image
#                @upload_files[file_type_sym].original_dimensions = ImageSize.path(@upload_files[file_type_sym].path).size.join("x")
#                @upload_files[file_type_sym].small_dimensions = @upload_files[file_type_sym].resize_from_s(Fs2File::IMAGE_JOB_SEEKER_PLACEHOLDER_SIZES[:small])
#                @upload_files[file_type_sym].medium_dimensions = @upload_files[file_type_sym].resize_from_s(Fs2File::IMAGE_JOB_SEEKER_PLACEHOLDER_SIZES[:medium])
#                @upload_files[file_type_sym].large_dimensions = @upload_files[file_type_sym].resize_from_s(Fs2File::IMAGE_JOB_SEEKER_PLACEHOLDER_SIZES[:large])
#              end
#              
#              raise 'ERRORS: ' + @upload_files[file_type_sym].errors.to_xml if !@upload_files[file_type_sym].valid?
#              @upload_files[file_type_sym].save(false)
#            end
#          end
#          
#        end
#    
#      rescue => e
#        puts 'Upload failed. ' + e.to_s
#        flash[:error] = 'Upload failed. Please try again.'
#        
#        # Delete the files
#        if @upload_files
#          @upload_files.each do |file_key, file_obj|
#            file_obj.delete
#          end
#        end
#        
#        raise 'ERRORS: Upload failed. ' + e.to_s
#      end
#  end
  
  # 
  # If 'job_seeker_id' is null, assume this skills profile will be assigned to a job
  #
  def save_skills_profile(flags = {})
    return nil if @skills.nil?
    
    begin
      
      # Create a new skills_profile object
      @skills_profile = Fs2SkillsProfile.new
      raise 'ERROR' if !@skills_profile.valid?

      if flags[:job_seeker_id]
        @skills_profile.job_seeker_id = flags[:job_seeker_id]
      elsif flags[:job_id]
        
      end
      @skills_profile.save(false)
      
      # -----------------------
      # 2. Set the 'skills_profile' id in the entire 5skills data structure
      # -----------------------
      if @skills
        @skills.each do |skill|
          if skill
            skill.skills_profile_id = @skills_profile.id
            
            skill.skill_details.each do |skill_details|
              skill_details.skills_profile_id = @skills_profile.id
            end
            
            skill.save(false)
          end
        end
      end
      
      # -----------------------
      # 3. Set the 'skills_profile' id in the 'additional_requirements' objects 
      # -----------------------
      if @additional_requirements
        @additional_requirements.each do |additional_requirement|
          additional_requirement.skills_profile_id = @skills_profile.id
          
          additional_requirement.save(false)
        end
      end
      
    rescue Exception => exc
      
      flash[:error] = 'Errors were found in the fields below, please check the messages next to each field'
      
      puts " XXX: " + exc.message
      
    end # rescue

    @skills_profile
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
  
  def update_job_seeker_profile
    
    @current_job_seeker = session[:person]
    
    respond_to do |format|
      
      #TODO:Add data fields check and ask to confirm after clicking 'cancel'
      if params[:cancel]
        
        format.html { 
          redirect_to :action => :view_job_seeker_profile, 
            :controller => :five_skills, 
            :job_seeker_id => @current_job_seeker.id }
          
      else
    
        Fs2JobSeeker.transaction do
          
          begin
            
            # -----------------------
            # 1. Save the 'job seeker' object & the 'skills_profile' object (to get the IDs)
            # -----------------------
            @temp_job_seeker = Fs2JobSeeker.new(params[:job_seeker])
            raise 'ERROR' if !@temp_job_seeker.valid?
                        
            # Update 'job_seeker' details
            attributes_to_change = {}
            
            @temp_job_seeker.attributes.each do |key, value|
            
              # TODO: Fix complex logic and the difference between the 'boolean' 'anonymous' and 'looking_for_work' fields)
              #  Currently, 'anonymous' is a 'true/false' field and 'looking_for_work' is a '0/1' field
              # COMPLEX LOGIC AHEAD -> watch out!
              
              # Check if the attribute is either 'anonymous' or 'looking_for_work' -> special treatment  
              if key == "anonymous" || key == "looking_for_work"
                attributes_to_change[key] = (!value.nil? && (value == 1 || value == true))
              
              # In case the 'new' values are nil, use the 'existing' job_seeker attribute value
              elsif value.nil?
                attributes_to_change[key] = @current_job_seeker.attributes[key]
                
              # Otherwise, use the 'new' attribute values
              else
                attributes_to_change[key] = value
              end
              
            end
            
            if attributes_to_change["anonymous"] && !@current_job_seeker.anonymous # 'true' field changed with this update (ignore previouse 'true' state)
              attributes_to_change["full_name_secret"] = @current_job_seeker.full_name
              attributes_to_change["full_name"] = "Anonymous"
              
              if @current_job_seeker.profile_photo_id
                attributes_to_change["profile_photo_id_secret"] = @current_job_seeker.profile_photo_id
                attributes_to_change["profile_photo_id"] = Fs2File::ANONYMOUS_SECRET_IDS[:profile_photo]
              end
            elsif !attributes_to_change["anonymous"] && @current_job_seeker.anonymous
              attributes_to_change["full_name"] = @current_job_seeker.full_name_secret
              attributes_to_change["full_name_secret"] = nil
              
              if @current_job_seeker.profile_photo_id
                attributes_to_change["profile_photo_id"] = @current_job_seeker.profile_photo_id_secret
                attributes_to_change["profile_photo_id_secret"] = nil
              end
            end
            
            # attributes_to_change = @current_job_seeker.attributes.merge(@temp_job_seeker.attributes) do |key, oldval, newval|
              # puts "-- TEST: " + key + " ; " + oldval.to_s + " ; " + newval.to_s
              # if !newval.nil?; newval; else oldval; end
            # end
            
            @current_job_seeker.update_attributes(attributes_to_change)
            
            # Destroy the current 'skills_profile' object and its children (and create a brand new object)
            # AND destroy current 'matches' (delete all 'fs2_skills_profiles_matches' entities with
            # matching job_seeker_id
            @current_skills_profile = Fs2SkillsProfile.find_by_job_seeker_id(@current_job_seeker.id)
            
            if @current_skills_profile
              js_sprofiles_match = Fs2SkillsProfilesMatch.find_by_js_skills_profile_id(@current_skills_profile.id)
              Fs2SkillsProfilesMatch.destroy_all(["js_skills_profile_id = ?", @current_skills_profile.id]) if js_sprofiles_match
              Fs2SkillsProfile.destroy(@current_skills_profile.id)
            end
            
            skills_profile = save_skills_profile({:job_seeker_id => @current_job_seeker.id})
            raise 'ERROR' if !skills_profile
            
            upload_files({:upload_cv => @current_job_seeker.id}, true)
            upload_files({:upload_profile_photo => @current_job_seeker.id}, true)
            
            flash[:notice] = 'Job seeker profile was created successfully!'
            flash[:error] = nil
  
            # Redirect back to the same page
            if params[:create_profile] || params[:update_profile] # If chose to just update the form, return to the edit screen
              
              # ************************************************
              #  1 >  Run the search
              # ************************************************
              search_entities(ENTITY_TYPES[:job], {:contact_details => true})
              
              # ************************************************
              #  2 >  Save the matches (with status "NEW")
              # ************************************************
              if @js_results_array
                
                # ************************************************
                #  3 >  Get the 'job_seeker' files
                # ************************************************ 
                prep_files(@current_job_seeker.id, [Fs2File::FILE_TYPES[:profile_photo]])
                
                js_hash = {}
                
                job_seeker_summary = {}
                job_seeker_summary[:files] = {}
                
                job_seeker_summary[:full_name] = session[:person].full_name
                                  
                if @upload_files[:profile_photo]
                  job_seeker_summary[:files][:profile_photo] = {
                    :id => @upload_files[:profile_photo].id,
                    :small_dimensions => @upload_files[:profile_photo].small_dimensions,
                    :medium_dimensions => @upload_files[:profile_photo].medium_dimensions}
                end
                
                transaction_h = {:email_type => Fs2Mailer::EMAIL_TYPES[:new_job_seeker_matches]}
                
                @js_results_array.each do |job|
                  match = Fs2SkillsProfilesMatch.new
                  
                  match.js_id = session[:person].id
                  match.js_skills_profile_id = skills_profile.id
                  match.js_match_status = 1 # new
                  
                  match.j_id = job[0]
                  match.j_skills_profile_id = job[1][:skills_profile_id]
                  match.j_match_status = 1 # new
                  
                  match.match_date = Time.now # new
                  match.match_points = job_seeker_summary[:match_points] = job[1][:match_points]
                  match.match_skills = job_seeker_summary[:matched_skills] = job[1][:matched_skills]
                  match.match_skills_details = job_seeker_summary[:matched_skill_details] = job[1][:matched_skill_details]
                  match.match_additional_requirements = job_seeker_summary[:matched_additional_requirements] = job[1][:matched_additional_requirements]
                  
                  job_seeker_summary[:cv_trans_status_id] = job[1][:cv_trans_status_id]
                  job_seeker_summary[:cv_trans_status_name] = job[1][:cv_trans_status_name]
                  job_seeker_summary[:cv_trans_updated_at] = job[1][:cv_trans_updated_at]
                  job_seeker_summary[:cv_trans_updated_at_formatted] = job[1][:cv_trans_updated_at_formatted]
                  job_seeker_summary[:cv_trans_updated_at_time_ago] = job[1][:cv_trans_updated_at_time_ago]
                  
                  match.save(false)
                  
                  # *************************************************************************************
                  #  3 >  Send RECRUITMENT AGENTS and HIRING MANAGERS job matches notifications -> email
                  # *************************************************************************************
                  
                  # --->   Recruitment agents   <---
                  # - - - - - - - - - - - - - - - - - - 
                  if job[1][:agency_contact_user_email] && !job[1][:agency_contact_user_email].blank?
                    transaction_h[:exchange_type] = Fs2Mailer::EMAIL_EXCHANGE_TYPES[:system_to_recruitment_agent] 
                    metadata_params_h = {
                      :recipients => [{
                        :id => job[1][:agency_contact_user_id], 
                        :email => job[1][:agency_contact_user_email], 
                        :name => job[1][:agency_contact_full_name]}]}
                   
                  # --->   Hiring managers   <---
                  # - - - - - - - - - - - - - - - - - - 
                  elsif job[1][:company_contact_user_email] && !job[1][:company_contact_user_email].blank?
                    transaction_h[:exchange_type] = Fs2Mailer::EMAIL_EXCHANGE_TYPES[:system_to_hiring_manager]
                    metadata_params_h = {
                      :recipients => [{
                        :id => job[1][:company_contact_user_id], 
                        :email => job[1][:company_contact_user_email], 
                        :name => job[1][:company_contact_full_name]}]}
                  end
                  
                  next if metadata_params_h.nil?
                  
                  # Populate 'job_seeker' hash for 'hiring managers' and 'recruitment agents'
                  js_hash["js_results_array"] = [[@current_job_seeker.id, job_seeker_summary]]               

                  # --->   Send 'job_seeker' details   <---
                  # - - - - - - - - - - - - - - - - - - - - 
                  send_message(metadata_params_h, js_hash, transaction_h)
                end
                
                # **********************************************************
                #  4 >  Send JOB SEEKER job matches notifications -> email
                # **********************************************************
                metadata_params_h = {
                  :recipients => [{
                    :id => session[:user].id, 
                    :email => session[:user].email, 
                    :name => session[:person].full_name}]} 
                 
                send_message(
                    metadata_params_h,
                    {"j_results_array" => @js_results_array},
                    {:email_type => Fs2Mailer::EMAIL_TYPES[:new_job_matches],
                    :exchange_type => Fs2Mailer::EMAIL_EXCHANGE_TYPES[:system_to_job_seeker]})
 
              end
              
              format.html { 
                redirect_to :action => :view_job_seeker_profile, 
                  :controller => :five_skills, 
                  :job_seeker_id => @current_job_seeker.id }
                
            # This is an AJAX call
            elsif params[:save_as_template]
              
              add_skills_profile_binders("search_job_seekers", true)
      
              format.html { render 'maintain_job_seeker_profile.html', :layout => 'five_skills'  }
                
            end
            
          rescue Exception => exc
            
            @job_seeker = @temp_job_seeker if @temp_job_seeker
            
            flash[:error] = 'Errors were found in the fields below, please check the messages next to each field'
            
            puts " XXX: " + exc.message
            
            add_skills_profile_binders("search_job_seekers", true)
              
            format.html { render 'maintain_job_seeker_profile.html', :layout => 'five_skills'  }          
          end # rescue
        end # transaction
        
      end # else      
    end # respond_to
  end
  
  
  
  # -- 
  #
  # Required fields:
  #  - params[:agency] => { :name => XX }
  #  - params[:agency_contact] => { :full_name => XX }
  #
  def save_agency_profile
    agency = agency_contact = nil
    
    if !get_param([:agency, :name]).blank?
      temp_agency = Fs2Organisation.new(params[:agency])
      temp_agency.organisation_type = Fs2Organisation::ORGANISATION_TYPES[:agency]
      raise 'ERROR' if !temp_agency.valid?
        
      agency = Fs2Organisation.find(:first, 
        :conditions => [ "lower(name) = ? AND organisation_type = ?", 
        get_param([:agency, :name]).downcase, Fs2Organisation::ORGANISATION_TYPES[:agency]])
      
      # 2. if no ID exists, create a new one
      if agency.nil?
        temp_agency.save(false)
        agency = temp_agency
        params[:job_attributes][:agency_id] = temp_agency.id
      else
        agency.update_attributes(temp_agency.attributes)
        params[:job_attributes][:agency_id] = agency.id
      end
      
      session[:agency] = agency
      
      # 3. Search for agency contact ID (by name)
      if !get_param([:agency_contact, :full_name]).blank?
        temp_agency_contact = Fs2Contact.new(params[:agency_contact])
        temp_agency_contact.contact_type = Fs2Contact::CONTACT_TYPES[:agency]
        temp_agency_contact.organisation_id = agency.id
        
        # If the logged-in user is the recruitment_agent, update its details 
        if session[:user].user_type_id == Fs2User::USER_TYPES[:recruitment_agent]
          agency_contact = session[:person]
        else
          agency_contact = Fs2Contact.find(:first,
            :conditions => [ "organisation_id = ? AND contact_type = ? AND lower(full_name) = ?", 
            agency.id, Fs2Contact::CONTACT_TYPES[:agency], get_param([:agency_contact, :full_name]).downcase ])
        end
        
        if agency_contact.nil?
          temp_agency_contact.user_id = session[:user] if session[:user].user_type_id == Fs2User::USER_TYPES[:recruitment_agent]
          temp_agency_contact.save(false)
          agency_contact = temp_agency_contact
          params[:job_attributes][:agency_contact_id] = temp_agency_contact.id
        else          
          attributes_to_change = agency_contact.attributes.merge(temp_agency_contact.attributes) do |key, oldval, newval|
            if !newval.nil?; newval; else oldval; end
          end
          
          agency_contact.update_attributes(attributes_to_change)
          params[:job_attributes][:agency_contact_id] = agency_contact.id
        end
        
        session[:person] = agency_contact
      end
    end
    
    {:agency => agency, :agency_contact => agency_contact}
  end
  
  
  
  # -- 
  #
  # Required fields:
  #  - params[:company] => { :name => XX }
  #  - params[:company_contact] => { :full_name => XX }
  #
  def save_company_profile
    company = company_contact = nil
    
    if !get_param([:company, :name]).blank?
      temp_company = Fs2Organisation.new(params[:company])
      temp_company.organisation_type = Fs2Organisation::ORGANISATION_TYPES[:company]
      raise 'ERROR' if !temp_company.valid?
        
      company = Fs2Organisation.find(:first, 
        :conditions => [ "lower(name) = ? AND organisation_type = ?", 
        get_param([:company, :name]).downcase, Fs2Organisation::ORGANISATION_TYPES[:company]])
      
      # 2. if no ID exists, create a new one
      if company.nil?
        temp_company.save(false)
        company = temp_company
        params[:job_attributes][:company_id] = temp_company.id 
      else
        company.update_attributes(temp_company.attributes)
        params[:job_attributes][:company_id] = company.id
      end
      
      session[:company] = company
      
      # 3. Search for company contact ID (by name)
      if !get_param([:company_contact, :full_name]).blank?
        temp_company_contact = Fs2Contact.new(params[:company_contact])
        temp_company_contact.contact_type = Fs2Contact::CONTACT_TYPES[:company]
        temp_company_contact.organisation_id = company.id
        raise 'ERROR' if !temp_company_contact.valid?
        
        # If the logged-in user is the recruitment_agent, update its details 
        if session[:user].user_type_id == Fs2User::USER_TYPES[:hiring_manager]
          company_contact = session[:person]
        else
          company_contact = Fs2Contact.find(:first, 
            :conditions => [ "organisation_id = ? AND contact_type = ? AND lower(full_name) = ?", 
            company.id, Fs2Contact::CONTACT_TYPES[:company], get_param([:company_contact, :full_name]).downcase ])
        end
        
        if company_contact.nil?
          temp_company_contact.user_id = session[:user] if session[:user].user_type_id == Fs2User::USER_TYPES[:hiring_manager]
          temp_company_contact.save(false)
          company_contact = temp_company_contact 
          params[:job_attributes][:company_contact_id] = temp_company_contact.id
        else
          attributes_to_change = company_contact.attributes.merge(temp_company_contact.attributes) do |key, oldval, newval|
            if !newval.nil?; newval; else oldval; end
          end
          
          company_contact.update_attributes(attributes_to_change)
          params[:job_attributes][:company_contact_id] = company_contact.id
        end

        session[:person] = company_contact
      end
    end
    
    {:company => company, :company_contact => company_contact}
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
  
  def save_job_seeker_profile
    
    respond_to do |format|
      
      #TODO:Add data fields check and ask to confirm after clicking 'cancel'
      if params[:cancel]
        
        format.html { redirect_to :action => :home, :controller => :five_skills }
          
      else
    
        Fs2JobSeeker.transaction do
          
          begin
            
            # -----------------------
            # 1. Save the 'job seeker' object & the 'skills_profile' object (to get the IDs)
            # -----------------------
            @job_seeker = Fs2JobSeeker.new(params[:job_seeker])
            raise 'ERROR' if !@job_seeker.valid?
            @job_seeker.save(false)
            
            raise 'ERROR' if !save_skills_profile({:job_seeker_id => @job_seeker.id})
            upload_files({:upload_cv => @job_seeker.id})
            upload_files({:upload_profile_photo => @job_seeker.id})
            
            flash[:notice] = 'Job seeker profile was created successfully!'
            flash[:error] = nil
  
            # Redirect back to the same page
            if params[:create_profile] # If chose to just update the form, return to the edit screen
              
              format.html { 
                redirect_to :action => :view_job_seeker_profile, 
                  :controller => :five_skills, 
                  :job_seeker_id => @job_seeker.id }
                
            # This is an AJAX call
            elsif params[:save_as_template]
              
              add_skills_profile_binders("search_job_seekers", true)
      
              format.html { render 'maintain_job_seeker_profile.html', :layout => 'five_skills'  }
                
            end
            
          rescue Exception => exc
            
            flash[:error] = 'Errors were found in the fields below, please check the messages next to each field'
            
            puts " XXX: " + exc.message
            
            add_skills_profile_binders("search_job_seekers", true)
              
            format.html { render 'maintain_job_seeker_profile.html', :layout => 'five_skills'  }          
          end # rescue
        end # transaction
        
      end # else      
    end # respond_to
  end
  
  def download_file
    @file = Fs2File.find_by_id(params[:file_id])
    
    send_file @file.path, :type => @file.mime_type, :disposition => 'attachment' if @file
  end
  
  def show_file
    @file = Fs2File.find_by_id(params[:file_id])
    
    send_file @file.path, :type => @file.mime_type, :disposition => 'inline' if @file
  end
  
  def view_organisation_summary(organisation_id, a_file_types)
    prep_files(organisation_id, a_file_types)
    
    respond_to do |format|
      
      format.json {
        if organisation_id
          @arr = {
            :status => "200",
            :action => params[:action],
            :files => Hash.new
          }
          
          @upload_files.each do |file_key, file|
            @arr[:files][file_key] = {
              :id => file.id
            }

            if file.large_dimensions
              @arr[:files][file_key][:large_dimensions] = {
                :width => file.large_dimensions.split("x")[0], 
                :height => file.large_dimensions.split("x")[1]  
              }
            end
          end
        else
          @arr = {
            :status => "100",
            :action => params[:action],
            :error => {
              :code => 1,
              :message => "'organisation_id' is missing!"
            }
          }
        end
          
        render :json => @arr.to_json, :callback => params[:callback] 
      }
      
    end
  end
  
  def view_company_summary
    view_organisation_summary(params[:organisation_id], [Fs2File::FILE_TYPES[:company_logo]])
  end
  
  def view_agency_summary
    view_organisation_summary(params[:organisation_id], [Fs2File::FILE_TYPES[:agency_logo]])
  end  
  
  def view_job_profile
    puts "   FFFFF: " + time_ago_in_words(Time.new).to_s
    
    if !params[:job_id]
      flash[:error] = 'No "job_id" provided!'
      render 'view_job_profile.html', :layout => 'five_skills'
      return
    end

    prep_job_profile(params[:job_id])
    
    render 'view_job_profile.html', :layout => 'five_skills'
  end
  
  def jobs_cv_delivery_log
    @jobs_trans = Fs2CvsToJobsTransaction.find(:all, :conditions => ["job_seeker_id = ?", session[:person].id.to_s], :order => "status_id ASC, updated_at DESC")
    @jobs_h = {} if @jobs_trans
    
    @jobs_trans.each do |job_trans|
      @upload_files = @skills_profile_matrix = nil
      
      prep_job_profile(job_trans.job_id)
      @jobs_h[job_trans.job_id] = @job
      @jobs_h[job_trans.job_id][:cv_trans_status_id] = job_trans.status_id
      @jobs_h[job_trans.job_id][:cv_trans_status_name] = job_trans.status_name
      @jobs_h[job_trans.job_id][:cv_trans_updated_at_formatted] = format_time(job_trans.updated_at.to_s) 
      @jobs_h[job_trans.job_id][:cv_trans_updated_at_time_ago] = format_time(job_trans.updated_at.to_s, TIME_FORMAT_TYPES[:time_ago])
      @jobs_h[job_trans.job_id][:skills_profile] = @skills_profile_matrix
      @jobs_h[job_trans.job_id][:files] = {}
      
      if @upload_files[:agency_logo]
        @jobs_h[job_trans.job_id][:files][:agency_logo] =  {
          :file_id => @upload_files[:agency_logo].id,
          :small_dimensions => @upload_files[:agency_logo].small_dimensions,
          :medium_dimensions => @upload_files[:agency_logo].medium_dimensions}
      end
      
      # Company logo
      if @upload_files[:company_logo]
        @jobs_h[job_trans.job_id][:files][:company_logo] =  {
          :file_id => @upload_files[:company_logo].id,
          :small_dimensions => @upload_files[:company_logo].small_dimensions,
          :medium_dimensions => @upload_files[:company_logo].medium_dimensions}
      end 
    end
    
    # @job = clean_attributes(jobs[0]) if jobs && jobs[0]
    
    render 'jobs_cv_delivery_log.html', :layout => 'five_skills'
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
  
  def cv_request_approve
    send_cv_emails(Fs2Mailer::EMAIL_TYPES[:cv_request_approved_for_job])
  end
  
  def cv_request_reject
    send_cv_emails(Fs2Mailer::EMAIL_TYPES[:cv_request_rejected_for_job])
  end
  
  def request_cv_from_job_seeker
    send_cv_emails(Fs2Mailer::EMAIL_TYPES[:cv_requested_for_job])
  end
  
  # email_type -
  #   cv_sent_for_job: @job_seeker, params[:job_id]
  #   request_cv_for_job: @contact, params[:job_seeker_id]
  #
  def send_cv_emails(email_type)
    
    job_id = job_seeker_id = nil
    
    if email_type == Fs2Mailer::EMAIL_TYPES[:cv_sent_for_job] ||
        email_type == Fs2Mailer::EMAIL_TYPES[:cv_request_rejected_for_job] ||
        email_type == Fs2Mailer::EMAIL_TYPES[:cv_request_approved_for_job]
        
      job_id = params[:job_id]
      job_seeker_id = session[:person].id
        
    elsif email_type == Fs2Mailer::EMAIL_TYPES[:cv_requested_for_job]
      
      job_id = session[:job].id
      job_seeker_id = params[:job_seeker_id]
      
    end
    
    
    
    prep_job_profile(job_id)
    js_hash = {:job => @job}
    js_hash[:job][:skills_profile] = @skills_profile_matrix if @skills_profile_matrix
    
    transaction_h = {:email_type => email_type}

    # --->   Recruitment agents   <---
    # - - - - - - - - - - - - - - - - - - 
    if @job[:au_email] && @job[:ac_full_name]

      transaction_h[:exchange_type] = Fs2Mailer::EMAIL_EXCHANGE_TYPES[:system_to_recruitment_agent] 
      metadata_params_h = {
        :recipients => [{
          :id => @job[:au_id], 
          :email => @job[:au_email], 
          :name => @job[:ac_full_name]}]}
      
    # --->   Hiring managers   <---
    # - - - - - - - - - - - - - - - - - - 
    elsif @job[:cu_email] && @job[:cc_full_name]

      transaction_h[:exchange_type] = Fs2Mailer::EMAIL_EXCHANGE_TYPES[:system_to_hiring_manager] 
      metadata_params_h = {
        :recipients => [{
          :id => @job[:cu_id], 
          :email => @job[:cu_email], 
          :name => @job[:cc_full_name]}]}
    
    else
      
      puts "---------------------------- ERROR ----------------------------"
      puts " Email and/or full name of the contact don't exist. Check the database for contact information for 'job_id:" + job_id + "'!"
      puts "---------------------------- ERROR ----------------------------"
      return
      
    end

    prep_job_seeker_profile(job_seeker_id)
    js_hash[:job_seeker] = {:id => @job_seeker.id, :full_name => @job_seeker.full_name}
    js_hash[:job_seeker][:skills_profile] = @skills_profile_matrix if @skills_profile_matrix
    
    # ----------------------------------------------
    # Error handling for test users without 'user' objects in the database
    # ----------------------------------------------
    if @job_seeker_user.nil?
      flash[:error] = "Oops! you tried to interact with a 'test' system user, try a different one!"
      view_job_seeker_matches
      return
    end
    
    # Profile Photo
    if @upload_files[:profile_photo]
      js_hash[:job_seeker][:profile_photo] = {
        :file_id => @upload_files[:profile_photo].id,
        :small_dimensions => @upload_files[:profile_photo].small_dimensions,
        :medium_dimensions => @upload_files[:profile_photo].medium_dimensions}
    end
    
    # CV
    if @upload_files[:cv]
      js_hash[:job_seeker][:cv] = {
        :file_id => @upload_files[:cv].id,
        :file_name => @upload_files[:cv].name,
        :file_mime_type => @upload_files[:cv].mime_type,
        :file_path => @upload_files[:cv].path}
    end

    # --->   Send 'job_seeker' details   <---
    # - - - - - - - - - - - - - - - - - - - - 
    send_message(metadata_params_h, js_hash, transaction_h)
    
    
    # - - - - - - - - - - - - - - - - - - - - - - - - - - -
    # --->   Send notification email to 'job_seeker'   <---
    # - - - - - - - - - - - - - - - - - - - - - - - - - - -
    transaction_h[:exchange_type] = Fs2Mailer::EMAIL_EXCHANGE_TYPES[:system_to_job_seeker]
    
    # Define the logos
    js_hash[:job][:files] = {}
    
    # Agency logo
    if @upload_files[:agency_logo]
      js_hash[:job][:files][:agency_logo] =  {
        :file_id => @upload_files[:agency_logo].id,
        :small_dimensions => @upload_files[:agency_logo].small_dimensions,
        :medium_dimensions => @upload_files[:agency_logo].medium_dimensions}
    end
    
    # Company logo
    if @upload_files[:company_logo]
      js_hash[:job][:files][:company_logo] =  {
        :file_id => @upload_files[:company_logo].id,
        :small_dimensions => @upload_files[:company_logo].small_dimensions,
        :medium_dimensions => @upload_files[:company_logo].medium_dimensions}
    end 
    
    # Set the recipients
    metadata_params_h = {
      :recipients => [{
        :id => @job_seeker_user.id, 
        :email => @job_seeker_user.email, 
        :name => @job_seeker.full_name}]} 
        
    # Clear attachments
    js_hash["attachments"] = nil
     
    send_message(metadata_params_h, js_hash, transaction_h)
    
    
    
    status_id = nil
    
    case email_type
      when Fs2Mailer::EMAIL_TYPES[:cv_sent_for_job]
        status_id = Fs2CvsToJobsTransaction::STATUS_TYPES[:cv_sent]
      when Fs2Mailer::EMAIL_TYPES[:cv_requested_for_job]
        status_id = Fs2CvsToJobsTransaction::STATUS_TYPES[:cv_requested]
      when Fs2Mailer::EMAIL_TYPES[:cv_request_approved_for_job]
        status_id = Fs2CvsToJobsTransaction::STATUS_TYPES[:cv_request_approved]
      when Fs2Mailer::EMAIL_TYPES[:cv_request_rejected_for_job]
        status_id = Fs2CvsToJobsTransaction::STATUS_TYPES[:cv_request_rejected]
    end
    
    cv_to_job_trans = Fs2CvsToJobsTransaction.find(:first, :conditions => ["job_seeker_id = ? AND job_id = ?", @job_seeker.id, @job[:j_id]])
    
    if cv_to_job_trans.nil?
      cv_job_trans = Fs2CvsToJobsTransaction.new({
        :job_seeker_id => @job_seeker.id,
        :job_id => @job[:j_id],
        :status_id => status_id})
      cv_job_trans.save(false)
    else
      cv_to_job_trans.update_attributes({:status_id => status_id})
    end
    
    case email_type
      when Fs2Mailer::EMAIL_TYPES[:cv_sent_for_job]
        flash[:notice] = "Yes! successfully sent your CV to this job!"
        view_job_profile 
      when Fs2Mailer::EMAIL_TYPES[:cv_requested_for_job]
        flash[:notice] = "Yes! successfully requested a CV from the following job seeker!"
        view_job_seeker_profile
      when Fs2Mailer::EMAIL_TYPES[:cv_request_approved_for_job]
        flash[:notice] = "Yes! successfully APPROVED the CV Request!"
        view_job_profile 
      when Fs2Mailer::EMAIL_TYPES[:cv_request_rejected_for_job]
        flash[:notice] = "Oh no! You have rejected the CV Request!"
        view_job_profile 
    end 
    
  end
  
  def send_cv_to_job
    send_cv_emails(Fs2Mailer::EMAIL_TYPES[:cv_sent_for_job])
  end
  
  def view_job_seeker_profile

    if !params[:job_seeker_id]
      flash[:error] = 'No "job_seeker_id" provided!'
      render 'view_job_seeker_profile.html', :layout => 'five_skills'
      return
    end
    
    prep_job_seeker_profile(params[:job_seeker_id])
    
    render 'view_job_seeker_profile.html', :layout => 'five_skills'
  end
  
  def prep_skills_profile(flags = {})
    
    if flags.empty?
      flash[:error] = "Can't find 'skills_profile' without 'flags'!"
      return
    end
    
    @sql = "select " +
      "sp.id sp_id, sp.job_seeker_id js_id, " + 
      "s.keyword_id s_kid, s_k.keyword s_keyword, " +  
      "s.priority sp, s.years_experience, s.self_rate, " + 
      "sd.keyword_id sd_kid, sd_k.keyword sd_keyword, sd.priority sdp, " + 
      "ar.keyword_id ar_kid, ar_k.keyword ar_keyword, ar.priority arp " + 
    "from "
    
    if flags[:job_seeker_id]
      @sql += 
        "fs2_job_seekers js LEFT JOIN " +
        "fs2_skills_profiles sp on (js.id = sp.job_seeker_id) LEFT JOIN "
    elsif flags[:job_id]
      @sql += 
        "fs2_jobs j LEFT JOIN " +
        "fs2_skills_profiles sp on (j.skills_profile_id = sp.id) LEFT JOIN "
    elsif flags[:skills_profile_id]
      @sql += 
        "fs2_skills_profiles sp LEFT JOIN "
    elsif flags[:template_id]
      @sql += 
        "fs2_templates t JOIN " +
        "fs2_skills_profiles sp on (t.skills_profile_id = sp.id) LEFT JOIN "
    end
    
    @sql += 
      "fs2_skills s on (sp.id = s.skills_profile_id) LEFT JOIN " +
      "fs2_keywords s_k on (s.keyword_id = s_k.id) LEFT JOIN " + 
      "fs2_skill_details sd on (s.id = sd.skill_id) LEFT JOIN " +
      "fs2_keywords sd_k on (sd.keyword_id = sd_k.id) LEFT JOIN " + 
      "fs2_additional_requirements ar on (sp.id = ar.skills_profile_id) LEFT JOIN " +
      "fs2_keywords ar_k on (s.keyword_id = ar_k.id) " + 
    "where "
    
    if flags[:job_seeker_id]
      @sql += "js.id = " + flags[:job_seeker_id].to_s
    elsif flags[:job_id]
      @sql += "j.id = " + flags[:job_id].to_s
    elsif flags[:skills_profile_id]
      @sql += "sp.id = " + flags[:skills_profile_id].to_s
    elsif flags[:template_id]
      @sql += "t.id = " + flags[:template_id].to_s
    end
       
    @skills_profiles = Fs2SkillsProfile.find_by_sql(@sql)
    
    @job_seeker_id = nil
    @js_skills_matrix = {
      1 => {:name => -1, :years_experience => -1, :self_rate => -1, :details => nil},
      2 => {:name => -1, :years_experience => -1, :self_rate => -1, :details => nil},
      3 => {:name => -1, :years_experience => -1, :self_rate => -1, :details => nil},
      4 => {:name => -1, :years_experience => -1, :self_rate => -1, :details => nil},
      5 => {:name => -1, :years_experience => -1, :self_rate => -1, :details => nil},
      :additional_requirements => nil}  
    @skills_profile_matrix = {
      "skill_1" => {:name => "", :years_experience => "", :self_rate => "", :details => Array.new(0)},
      "skill_2" => {:name => "", :years_experience => "", :self_rate => "", :details => Array.new(0)},
      "skill_3" => {:name => "", :years_experience => "", :self_rate => "", :details => Array.new(0)},
      "skill_4" => {:name => "", :years_experience => "", :self_rate => "", :details => Array.new(0)},
      "skill_5" => {:name => "", :years_experience => "", :self_rate => "", :details => Array.new(0)}, 
      :additional_requirements => Array.new(0)}
    
    @skills_profiles.each do |skills_profile|

#      @job_seeker_id = skills_profile.js_id.to_i
      js_skill_priority = skills_profile.sp.to_i
      js_skill_detail_priority = skills_profile.sdp.to_i if !skills_profile.sdp.nil?
      js_additional_requirements_priority = skills_profile.arp.to_i if !skills_profile.arp.nil?
        
      # SKILLS
      if !skills_profile.sp.nil?
        if @js_skills_matrix[js_skill_priority][:name] == -1 
          @js_skills_matrix[js_skill_priority][:name] = skills_profile.s_kid.to_i
          @js_skills_matrix[js_skill_priority][:years_experience] = skills_profile.years_experience.to_i
          @js_skills_matrix[js_skill_priority][:self_rate] = skills_profile.self_rate.to_i
          
          @skills_profile_matrix["skill_" + js_skill_priority.to_s][:name] = skills_profile.s_keyword
          @skills_profile_matrix["skill_" + js_skill_priority.to_s][:years_experience] = skills_profile.years_experience.to_i
          @skills_profile_matrix["skill_" + js_skill_priority.to_s][:self_rate] = skills_profile.self_rate
          
        end
      end
      
      # DETAIL
      if !skills_profile.sdp.nil?
        if !@js_skills_matrix[js_skill_priority][:details]
          @js_skills_matrix[js_skill_priority][:details] = Hash.new
        end
        
        # ASSUMPTION: Duplicates are consistent, don't need to check if a value already exists, just override
        if !js_skill_detail_priority.nil? && !skills_profile.sd_kid.nil?
          @js_skills_matrix[js_skill_priority][:details][js_skill_detail_priority] = skills_profile.sd_kid.to_i
          @skills_profile_matrix["skill_" + js_skill_priority.to_s][:details].push(skills_profile.sd_keyword) 
        end
      end
      
      # ADDITIONAL REQUIREMENTS
      if !skills_profile.arp.nil?
        if !@js_skills_matrix[:additional_requirements] 
          @js_skills_matrix[:additional_requirements] = Hash.new
        end
        
        # ASSUMPTION: Duplicates are consistent, don't need to check if a value already exists, just override
        if !js_additional_requirements_priority.nil? && !skills_profile.ar_kid.nil?
          @js_skills_matrix[:additional_requirements][js_additional_requirements_priority] = skills_profile.ar_kid.to_i
          @skills_profile_matrix[:additional_requirements].push(skills_profile.ar_keyword)
        end
      end
      
    end
    
    # Convert the arrays to strings
    5.times do |i|
      @skill_key = "skill_" + (i+1).to_s
      
      @skills_profile_matrix[@skill_key][:details] = @skills_profile_matrix[@skill_key][:details].join(",")
    end
    @skills_profile_matrix[:additional_requirements] = @skills_profile_matrix[:additional_requirements].join(",")

  end
  
end
