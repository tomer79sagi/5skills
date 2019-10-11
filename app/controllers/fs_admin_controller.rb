# require 'yaml'

class FsAdminController < FiveSkillsController
  
  
  def admin_home
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
        
    render 'MVP2_admin_home.html', :layout => '__recruiter_home_layout'
  end
  
    
    
  # ***************************************
  #  ADMIN PAGES
  # ***************************************
  
  def admin_main
    reset_session
    session[:admin] = true
    init_person_objects
    
    redirect_to :admin_manage_job_seekers
  end
  
  def admin_manage_job_seekers
    @job_seekers = Fs2JobSeeker.find(
      :all,
      :joins => "LEFT JOIN `fs2_users` ON fs2_users.id = fs2_job_seekers.user_id" ,
      :select => "fs2_job_seekers.*, fs2_users.email",
      :order => "fs2_job_seekers.updated_at DESC, fs2_job_seekers.id DESC")
      
    render 'admin_manage_job_seekers.html', :layout => 'fs_admin_layout'
  end
  
  def admin_manage_jobs
    @jobs = Fs2Job.find(
      :all,
      :select => "fs2_jobs.*" + 
        ", company.name company_name, company_contact.id company_contact_id, company_contact.full_name company_contact_full_name" +
        ", company_contact_user.id company_contact_user_id, company_contact_user.email company_contact_user_email" + 
        ", agency.name agency_name, agency_contact.id agency_contact_id, agency_contact.full_name agency_contact_full_name" + 
        ", agency_contact_user.id agency_contact_user_id, agency_contact_user.email agency_contact_user_email",
      :joins => 
        " LEFT JOIN fs2_organisations company on company.id = fs2_jobs.company_id" +
        " LEFT JOIN fs2_organisations agency on agency.id = fs2_jobs.agency_id" + 
        " LEFT JOIN fs2_contacts company_contact on company_contact.id = fs2_jobs.company_contact_id" + 
        " LEFT JOIN fs2_contacts agency_contact on agency_contact.id = fs2_jobs.agency_contact_id" +
        " LEFT JOIN fs2_users company_contact_user on company_contact_user.id = company_contact.user_id" + 
        " LEFT JOIN fs2_users agency_contact_user on agency_contact_user.id = agency_contact.user_id",
      :order => "fs2_jobs.updated_at DESC, fs2_jobs.id DESC")
      
    render 'admin_manage_jobs.html', :layout => 'fs_admin_layout'
  end
  
  def admin_manage_templates
    @templates = Fs2SkillsProfile.find(
      :all,
      :conditions => ["profile_type = ?", FS_PROFILE_TYPES[:template]],
      :order => "updated_at DESC")
      
    render 'admin_manage_templates.html', :layout => 'fs_admin_layout'
  end
  
  def admin_new_template
    render 'admin_maintain_template.html', :layout => 'fs_admin_layout_edit_template'
  end
  
  def admin_edit_template
   
    @fs_profiles = fetch_skills_profiles({:skills_profile_id => params[:template_id]}, {:template => true})
    set_active_fs_profile
    
    # add_ajax_start_up_actions("search_job_seekers")
    
    render 'admin_maintain_template.html', :layout => 'fs_admin_layout_edit_template'
  end
  
  def admin_edit_job
   
    @job = fetch_job_profile(params[:job_id])
    @fs_profiles = @job[:fs_profiles]
    set_active_fs_profile
    
    # add_ajax_start_up_actions("search_job_seekers")
    
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
    
    render 'admin_maintain_job.html', :layout => 'fs_admin_layout_edit_job'
  end
  
  def admin_save_job_ajax
    
    # --- Update the organization details
    
    if params[:organization_data][:id].to_i != -1 && params[:organization_data][:name] && !params[:organization_data][:name].blank?
      sql = "update fs2_organisations set " + 
        "name = '" + params[:organization_data][:name].to_s + "'" + 
        ", email = '" + params[:organization_data][:jobs_email].to_s + "'"
      sql += ", phone = '" + params[:organization_data][:phone].to_s + "'" if params[:organization_data][:phone]
      sql += " where id = " + params[:organization_data][:id].to_s 
      
      Fs2Organisation.connection.execute(sql)
    else
      organization = Fs2Organisation.new
      organization.name = params[:organization_data][:name].to_s
      organization.email = params[:organization_data][:jobs_email].to_s
      organization.phone = params[:organization_data][:phone].to_s + "'" if params[:organization_data][:phone]
      organization.save(false)
      
      params[:organization_data][:id] = organization.id
    end
    
    
    # --- Update the job details
    
    if params[:job_data]
      
      # Existing job
      if params[:job_data][:id].to_i != -1 && params[:job_data][:title] && !params[:job_data][:title].blank?
        sql = "update fs2_jobs set title = '" + params[:job_data][:title].to_s + "'"
        sql += ", company_id = " + get_param(["organization_data", "id"]).to_s if get_param(["organization_data", "id"]) && !get_param(["organization_data", "id"]).blank? 
        sql += ", description = '" + get_param(["job_data", "description"], [/'/, "\\\\\'"]).to_s + "'" if get_param(["job_data", "description"]) && !get_param(["job_data", "description"]).blank?
        sql += " where id = " + params[:job_data][:id]
          
        Fs2Job.connection.execute(sql)
      else
       
      end
      
    end
    
    # --- Update the organization contact details
    
    # --- Update the organization user details
    
    Fs2SkillsProfile.transaction do
          
      begin
        
        
        # --- DELETE EXISTING FS_PROFILE
        
        if params[:job_data] && params[:job_data][:id]
          
          # Call the 'delete' SQL function to be more efficient when calling the DB (Rails will perform 2-3 queries for each table when a 'destroy' or 'delete' occurs)
          Fs2SkillsProfilesMatch.connection.execute("delete from fs2_skills_profiles_matches where js_skills_profile_id = " + params[:fs_profile_data][:id])
          Fs2SkillsProfile.connection.execute("delete from fs2_skills_profiles where id = " + params[:fs_profile_data][:id])
          Fs2Skill.connection.execute("delete from fs2_skills where skills_profile_id = " + params[:fs_profile_data][:id])
          Fs2SkillDetail.connection.execute("delete from fs2_skill_details where skills_profile_id = " + params[:fs_profile_data][:id])
          Fs2AdditionalRequirement.connection.execute("delete from fs2_additional_requirements where skills_profile_id = " + params[:fs_profile_data][:id])
          
        end
        
        
        # --- CREATE NEW FS_PROFILE
        
        skills_profile = save_fs_profile({:label => params[:job_data][:title]}, {
          :profile_type => FS_PROFILE_TYPES[:user_profile],
          :entity_type => ENTITY_TYPES[:job],
          :entity_id => params[:job_data][:id]})
          
        raise 'ERROR' if !skills_profile
        
        flash[:notice] = 'Template was saved successfully!'
        flash[:error] = nil
        
        @arr = {
            :status => "200",
            :action => "save_job_fs_profile",
            :message => "Successfully saved profile!"
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
  
  def admin_save_template_ajax
    
    Fs2SkillsProfile.transaction do
          
      begin
        
        
        # --- DELETE EXISTING FS_PROFILE
        
        if params[:entity_ids_to_save] && params[:entity_ids_to_save][:template_id]
          
          where_clause = params[:entity_ids_to_save][:template_id].to_s
          # where_clause = params[:entity_ids_to_save][:template_id].to_s + " AND profile_type = " + FS_PROFILE_TYPES[:template].to_s
          
          # Call the 'delete' SQL function to be more efficient when calling the DB (Rails will perform 2-3 queries for each table when a 'destroy' or 'delete' occurs)
          # Fs2SkillsProfilesMatch.connection.execute("delete from fs2_skills_profiles_matches where js_skills_profile_id = " + where_clause)
          Fs2SkillsProfile.connection.execute("delete from fs2_skills_profiles where id = " + where_clause)
          Fs2Skill.connection.execute("delete from fs2_skills where skills_profile_id = " + where_clause)
          Fs2SkillDetail.connection.execute("delete from fs2_skill_details where skills_profile_id = " + where_clause)
          Fs2AdditionalRequirement.connection.execute("delete from fs2_additional_requirements where skills_profile_id = " + where_clause)
          
        end
        
        
        # --- CREATE NEW FS_PROFILE
        
        skills_profile = save_fs_profile({:label => params[:template_data][:title]}, {:profile_type => FS_PROFILE_TYPES[:template]})
          
        raise 'ERROR' if !skills_profile
        
        flash[:notice] = 'Template was saved successfully!'
        flash[:error] = nil
        
        @arr = {
            :status => "200",
            :action => "save_template_fs_profile",
            :message => "Successfully saved profile!"
          }
        
      rescue Exception => exc
        
        # @job_seeker = @temp_job_seeker if @temp_job_seeker
        
        flash[:error] = 'Errors were found in the fields below, please check the messages next to each field'
        
        @arr = {
            :status => "101",
            :action => "save_template_fs_profile"
          }
                  
      end # rescue
    end # transaction
    
    respond_to do |format|
      
      format.json {  
        render :json => @arr.to_json, :callback => params[:callback] 
      }
      
    end
    
  end
  
  def admin_god
    
    @job_seekers = Fs2JobSeeker.find(
      :all,
      :joins => "LEFT JOIN `fs2_users` ON fs2_users.id = fs2_job_seekers.user_id" ,
      :select => "fs2_job_seekers.*, fs2_users.email",
      :order => "fs2_job_seekers.updated_at DESC, fs2_job_seekers.id DESC")
      
    @contacts = Fs2Contact.find(
      :all,
      :joins => ["LEFT JOIN `fs2_users` ON fs2_users.id = fs2_contacts.user_id ",
        "LEFT JOIN fs2_jobs job_agent ON job_agent.agency_contact_id = fs2_contacts.id", 
        "LEFT JOIN fs2_jobs job_recruiter ON job_recruiter.company_contact_id = fs2_contacts.id"],
      :select => "fs2_contacts.*, fs2_users.email, job_agent.id agent_job_id, job_agent.title agent_job_title, job_recruiter.id recruiter_job_id, job_recruiter.title recruiter_job_title",
      :order => "fs2_contacts.updated_at DESC, fs2_contacts.id DESC")
    
    render 'admin_god.html', :layout => 'fs_admin_layout'
    
  end
  
  def clone_login
    
    return if !params[:user_id]
    
    reset_session
    session[:user] = Fs2User.find_by_id(params[:user_id])
    init_person_objects
    
    if session[:user]
      
      if session[:user].user_type_id == Fs2User::USER_TYPES[:job_seeker]
        
        if session[:user].status_id == Fs2User::USER_STATUSES[:at_landing_page]
            redirect_to :action => :create_job_seeker_profile, :controller => :fs_job_seeker
        else
          redirect_to :action => :edit_job_seeker_profile, :controller => :fs_job_seeker, :job_seeker_id => session[:person].id
        end
        
      elsif session[:user].user_type_id == Fs2User::USER_TYPES[:hiring_manager] || 
          session[:user].user_type_id == Fs2User::USER_TYPES[:recruitment_agent]
          
        if session[:jobs]
          redirect_to :action => :edit_job_profile, :controller => :fs_job, :job_id => session[:jobs][:active_job_id]
        else
          redirect_to :action => :create_job_profile, :controller => :fs_job
        end
        
      end
      
      return
    end
    
  end
  
  def demo_job_access
    # Hash -> demo_id: user_id
    demo_job_users = {
      1 => 43
    }
    
    if !params[:demo_id] || demo_job_users[params[:demo_id].to_i].nil?
      reset_session
      redirect_to :home, :controller => :five_skills
    end
    
    params[:user_id] = demo_job_users[params[:demo_id].to_i]
    clone_login
  end
  
  def demo_job_seeker_access
    # Hash -> demo_id: user_id
    demo_job_seeker_users = {
      1 => 93
    }
    
    if !params[:demo_id] || demo_job_seeker_users[params[:demo_id].to_i].nil?
      reset_session
      redirect_to :home, :controller => :five_skills
    end 
    
    params[:user_id] = demo_job_seeker_users[params[:demo_id].to_i]
    clone_login
  end
  
  def tags_demo
    render 'tags_demo.html', :layout => 'fs_admin_layout'
  end
  
  def tags_demo_edit
    render 'tags_demo_edit.html', :layout => 'fs_profile_edit_layout'
  end
  
  def tags_demo_import
    render 'tags_demo_import.html', :layout => 'fs_admin_layout'
  end
  
  def admin_keywords
    add_field_binder("search_keyword-name", "search_keyword-id", "search_keywords", FIELD_COLLECTION_TYPES[:keywords], 
      {:autocomplete => false,
        :onsearch => "search_keywords"})
    
    render 'keywords_admin.html', :layout => 'fs_admin_layout'
  end
  
  def create_job_profile
    render 'create_job_profile.html', :layout => 'fs_admin_layout'
  end
  
  def save_keyword_replacement
    if params['keyword_id'] && params['skill_id']
      Fs2Keyword.update(params['keyword_id'].to_i, :replace_with_skill_id => params['skill_id'].to_i)
    end
    
    respond_to do |format|
      
      format.json {
        @arr = {
            :status => "200",
            :action => params[:action],
            :keyword_id => params['keyword_id'].to_i             
          }
          
        render :json => @arr.to_json, :callback => params[:callback] 
      }
      
    end      
  end
  
  def search_keywords
    db_search_keywords
    
    respond_to do |format|
      
      format.json {
        @arr = {
            :status => "200",
            :action => params[:action],
            :results => @js_keywords
          }
          
        render :json => @arr.to_json, :callback => params[:callback] 
      }
      
    end    
  end  
  
  def db_search_keywords
    @results_keywords = Fs2Keyword.find(
      :all, 
      :joins => "LEFT JOIN fs2_skill_keywords sk ON sk.id = fs2_keywords.replace_with_skill_id",
      :select => "fs2_keywords.id kid, fs2_keywords.keyword, sk.id sid, sk.en_US", 
      :conditions => ["fs2_keywords.keyword LIKE ?", "%#{params['keyword_name']}%"])
      
    return if @results_keywords.nil?
    
    @js_keywords = Hash.new
    
    @results_keywords.each do |keyword|
      js_id = keyword.kid.to_i
      
      @js_keywords[js_id] = {
        :keyword => keyword.keyword,
        :replacement_skill_id => keyword.sid.to_i,
        :replacement_skill_name => keyword.en_US.to_s
      }
    end
  end
end
