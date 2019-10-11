# require 'image_size'
# require 'yaml'

# require 'watir'
# require 'watir-webdriver'
# require 'scrubyt'
# require 'firewatir'
# require 'mechanize'
# require 'linkedin-scraper'

require "benchmark"

class FiveSkillsController < FsSearchController

    
  # A -> CONSTRUCT SKILLS KEYWORD MATRIX
  
  before_filter :___create_fs_profile_from_request, 
    :only => [
      :fajax__publish_job,
      
      :save_job_fs_profile, :ajax_save_job_fs_profile, :search_jobs,
      :save_job_seeker_fs_profile, :search_job_seekers, :ajax_save_job_seeker_fs_profile,
      :ajax_search_job_seekers, 
      
      :ajax_apply_to_job_post,
      
      :admin_save_template_ajax, :admin_save_job_ajax]
  
  
  # B -> CREATE DATABASE-READY SKILLS OBJECT STRUCTURE    
  
  # -------- ADDED on 16 Aug 2014 --------
  
  before_filter :___create_db_ready_fs_profile, 
    :only => [
      :fajax__publish_job,
      
      :save_job_fs_profile, :ajax_save_job_fs_profile, 
      :save_job_seeker_fs_profile, :ajax_save_job_seeker_fs_profile_ajax, 
      :ajax_search_job_seekers,
      
      :ajax_apply_to_job_post,
      
      :admin_save_template_ajax, :admin_save_job_ajax
    ]
      
            
  
  # B -> CREATE DATABASE-READY SKILLS OBJECT STRUCTURE
  
  # -------- COMMENTED on 16 Aug 2014 --------
   
  # before_filter :create_db_ready_fs_profile, 
    # :only => [
      # :save_job_fs_profile, :ajax_save_job_fs_profile, 
      # :save_job_seeker_fs_profile, :ajax_save_job_seeker_fs_profile_ajax, 
      # :ajax_search_job_seekers,
#       
      # :ajax_apply_to_job_post,
#       
      # :admin_save_template_ajax, :admin_save_job_ajax]
      
      
  # C -> INIT SESSION FROM COOKIE (for AJAX)
  before_filter :init_session_from_cookies, 
    :only => [
      :ajax_save_job_seeker_fs_profile, 
      :admin_save_template_ajax,
      :admin_save_job_ajax]      

  def privacy_policy
    render 'privacy_policy.html', :layout => '__blank_layout' 
  end

  def create(object_s, type_s = basic)
    returned_obj = nil
    
    case object_s
      when "person__job_seeker"
        
        case type_s
          when "basic"
            
            returned_obj = Fs2JobSeeker.new
            returned_obj.save(false)
            
        end
        
      when "user__job_seeker"
        # Create USER
        returned_obj = Fs2User.new({
          :user_type_id => Fs2User::USER_TYPES[:job_seeker],
          :status_id => Fs2User::USER_STATUSES[:scraped],
          :referral_id => Fs2User::USER_REFERRALS[:added_through_friend]
        })
        returned_obj.email = lin_profile['emailAddress'] if lin_profile['emailAddress']
        returned_obj.save(false)
    end
    
    returned_obj
      
  end


  # 
  # This method checks if certain flags exist in the SESSION and PARAMS objects.
  # This method can check multiple parameters using the AND operator, ALL statuses must exist for a true response
  #
  # - Return:
  #   This method returns a TRUE or FALSE result based on the conditions checked (using the AND operator)
  #
  # - Examples:
  #   status_a = ["logged_in", "has_cv", "has_jobs"]
  #   status_a = ["user__job_seeker", "person__job_seeker"]
  #
  def is(status_a)
        
    flags_output = "" # Output
    final_response = true
    
    # If the 'status_a' is a single string (and not an array), convert it to an Array
    status_a = [status_a] if status_a && status_a.instance_of?(String)
    
    status_flag_a = status_a.collect { |flag| false }
    
    # --- Perform basic checks
    # return true if status_a.nil? && session[:user]
    # --- Handle bizarre exception
    # return "!nil" if (status_a[0] == "user__job_seeker" || status_a[0] == "recruiter") && session[:user].nil?
    
    return false if status_a.nil?
    
    puts "------- " + params[:active_user].to_s + " ; " +  ENTITY_TYPES[:job_seeker].to_s
    
    # --- Commented out: avoid quick validation, allow below process to validate the algorithm
    # return false if (status_a[0] == "user__job_seeker" || status_a[0] == "recruiter") && session[:user].nil?
    
    status_a.each_index do |flag_index|
      case status_a[flag_index]
        when "user__job_seeker"
          status_flag_a[flag_index] = true if 
            (session[:user] && session[:user].user_type_id == Fs2User::USER_TYPES[:job_seeker]) ||
            (params[:active_user] == ENTITY_TYPES[:job_seeker])
        when "person__job_seeker"
          status_flag_a[flag_index] = true if
            (session[:person] && session[:person].instance_of?(Fs2JobSeeker)) ||
            (params[:active_user] == ENTITY_TYPES[:job_seeker])
        when "recruiter"
          status_flag_a[flag_index] = true if session[:user] && 
            (session[:user].user_type_id == Fs2User::USER_TYPES[:recruitment_agent] || session[:user].user_type_id == Fs2User::USER_TYPES[:hiring_manager])  
        when "has_jobs"
          status_flag_a[flag_index] = true if session[:jobs] && session[:jobs][:active_job_id]
            
      end
    end
    
    status_a.each_index do |flag_index|
      if status_flag_a[flag_index] == false
        final_response = false
        break
      end
      flags_output << " | " + status_a[flag_index] + ": " + status_flag_a[flag_index].to_s
    end
    
    puts flags_output.to_s
    final_response
    
  end


  # 
  # This method checks if a certain parameter exists in the SESSION or the PARAM hash objects
  #  1. SESSION
  #  2. PARAMS
  #
  def id(entity_name)
    entity_id = nil
    
    case entity_name
      when "job"
        entity_id = params[:job_id]
      when "person__job_seeker"
        entity_id = session[:person].id if is("person__job_seeker")
        entity_id = params[:job_seeker_id] if entity_id.nil?
      when "user__job_seeker"
        entity_id = session[:user].id if is("user__job_seeker")
        entity_id = params[:user_id] if entity_id.nil?
      when "job_seeker__fs_profile"
        entity_id = session[:fs_profiles_ids][:job_seeker]
        entity_id = params[:job_seeker__fs_profile_id] if entity_id.nil?
      when "job__fs_profile"
        entity_id = session[:fs_profiles_ids][:job]
        entity_id = params[:job__fs_profile_id] if entity_id.nil?     
    end 
    
    entity_id
  end  
  

  # ------- TESTS

  def TEST_indeed
    
  end

  def mechanize
    
    
    render 'linkedin', :layout => '__linkedin_layout'
    return
    
    
    
    # profile = Linkedin::Profile.get_profile("http://il.linkedin.com/in/tomersagi")
    # # profile = Linkedin::Profile.get_profile("http://www.linkedin.com/profile/view?id=4850814")
#     
    # puts "X: " + profile.first_name          #the First name of the contact
    
    
    
    # browser = Watir::Browser.new
    # sleep 3
    # browser.goto 'http://linkedin.com'
    # sleep 1
    
    # if session[:page].nil?
      # agent = Mechanize.new
      # agent.agent.http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      # session[:page] = agent.get 'https://www.linkedin.com/profile/view?id=4850814'
    # end
#     
    # endorsements = session[:page].at('ul[class="skills-section"]')
    
    # property_data = Scrubyt::Extractor.define :agent => :firefox do
    property_data = Scrubyt::Extractor.define do
      
      
      # ----- LINKEDIN
      
      
       # fetch          'https://www.linkedin.com/in/tomersagi'
#        
       fetch          'https://www.linkedin.com/uas/login'
       fill_textfield 'session_key', 'tomer@tomersagi.com'
       fill_textfield 'session_password', 'tomer66'
       submit
    
       click_link_and_wait 'Connections', 5
    
       # vcard "//li[@class='vcard']" do
         # first_name  "//span[@class='given-name']"
         # second_name "//span[@class='family-name']"
         # email       "//a[@class='email']"
       # end
       
       
       # ----- EBAY
       
        # fetch 'http://www.ebay.com/'
        # fill_textfield 'satitle', 'ipod'
        # submit
        # click_link 'Apple iPod'
#         
        # record do
          # item_name 'APPLE NEW IPOD MINI 6GB MP3 PLAYER SILVER'
          # price '$71.99'
        # end
        # next_page 'Next >', :limit => 5
#     
    end
    
    puts property_data.to_xml
    
  end
   
  
  # ***************************************
  #  GENERAL PAGES
  # ***************************************
  
  def home
    # session[:user] = Fs2User.find_by_id(cookies[:user_id]) if session[:user].nil? && cookies[:user_id]
    
    if session[:user] && 
        session[:user].status_id && session[:user].status_id == Fs2User::USER_STATUSES[:linkedin_signed_in] && 
        session[:user].user_type_id && session[:user].user_type_id = Fs2User::USER_TYPES[:job_seeker]
      redirect_to :action => :view_seeker_profile, :controller => :fs_job_seeker
      return
    else
      key = params[:k] if params[:k]
      key = params[:key] if params[:key]
      
      if key
        if key == "A" || key == "a" # campaign 1
          session[:user_referral] = Fs2User::USER_REFERRALS[:campaign_1_email_invite_1]
        elsif key == "B" || key == "b" # campaign 1
          session[:user_referral] = Fs2User::USER_REFERRALS[:campaign_1_email_invite_2]
        elsif key == "C" || key == "c" # campaign 1
          session[:user_referral] = 3
        elsif key == "D" || key == "d" # campaign 2, get anonymous. get employed
          session[:user_referral] = 4
        elsif key == "E" || key == "e" # campaign 2, show your skills, not your face.
          session[:user_referral] = 5
        else
          session[:user_referral] = Fs2User::USER_REFERRALS[:unknown]
        end
      else
        session[:user_referral] = Fs2User::USER_REFERRALS[:non_campaign]  
      end
        
    end
    
    if session[:user_referral] && session[:user_referral] == Fs2User::USER_REFERRALS[:campaign_1_email_invite_2]
      render 'home_logged_out_2.html', :layout => '__seeker_homepage_layout'
    elsif session[:user_referral] && session[:user_referral] == 3
      render 'home_logged_out_3.html', :layout => '__seeker_homepage_layout'
    elsif session[:user_referral] && session[:user_referral] == 4
      render 'home_logged_out_4.html', :layout => '__seeker_homepage_layout'
    elsif session[:user_referral] && session[:user_referral] == 5
      render 'home_logged_out_5.html', :layout => '__seeker_homepage_layout'
    else
      render 'home_logged_out_5.html', :layout => '__seeker_homepage5_layout'
    end

  end
  
  
  def init_session_from_cookies
    if session[:user].nil?
      if cookies[:user_id].nil?
        session[:user] = Fs2User.new({:user_type_id => Fs2User::USER_TYPES[:job_seeker], :status_id => params[:status_id]})
        session[:user].save(false)
        cookies[:user_id] = session[:user].id
      else
        session[:user] = Fs2User.find_by_id(cookies[:user_id])
      end
    end
  end
  
  
  def reset_user_session
    # Fs2User.delete(session[:user].id) if session[:user]
    # Fs2UserConnector.connection.execute("delete from fs2_user_connectors where user_id = " + session[:user].id.to_s) if session[:user]
    # Fs2JobSeeker.connection.execute("delete from fs2_job_seekers where user_id = " + session[:user].id.to_s) if session[:user]
#     
    # fs_profile = Fs2SkillsProfile.find_by_entity_id(session[:user].id) if session[:user]
    # delete_fs_profile_by_fs_profile_id(fs_profile.id) if fs_profile
    
    reset_session
    cookies.delete :user_id
    
    redirect_to :home 
  end
  
  
  
  
  def public_profile
    if params[:profile_name] == 'tomersagi'
      render 'view_job_seeker_profile_public.html', :layout => 'five_skills_short'
    elsif params[:profile_name] == 'promng_job_1'
      render 'view_job_1_profile_public.html', :layout => 'five_skills_short'
    elsif params[:profile_name] == 'heveritr_job_1'
      render 'view_job_2_profile_public.html', :layout => 'five_skills_short'
    else
      render 'home.html', :layout => 'five_skills'
    end
  end
  
  def ___create_fs_profile_from_request
    
    return if params['skills_profile'].nil? || params['skills_profile'].length == 0
    
    skill_ids = params['skills_profile'].collect { |skill| skill[:id].to_i }.join(",")
    
    # -- 1 - SIMPLIFIED form - only by skill
    
    sql = "select DISTINCT" +
      " ind.id industry_id, ind.name industry_name," +
      " cat.id category_id, cat.category_name," +
      " s_k.id s_kid, s_k.keyword skill_name," +
      " group_concat(related.related_skill_id order by related.related_skill_id asc separator ',') rel_skills_ids," +
      " group_concat(rel_keyword.keyword order by related.related_skill_id asc separator ',') rel_skills_names," +
      " group_concat(related.related_strength order by related.related_skill_id asc separator ',') rel_skills_strength"
      
    sql += " FROM" + 
      " fs2_keywords s_k" +
      " LEFT JOIN fs2_skills_related related on (related.skill_id = s_k.id)" +
      " LEFT JOIN fs2_keywords rel_keyword on (rel_keyword.id = related.related_skill_id)" + 
      " LEFT JOIN fs2_map_skill_to_category skill_cat on (s_k.id = skill_cat.skill_id) " +
      " LEFT JOIN fs2_skill_categories cat on (cat.id = skill_cat.skill_category_id)" + 
      " LEFT JOIN fs2_map_category_to_industry cat_ind on (cat_ind.category_id = skill_cat.skill_category_id)" + 
      " LEFT JOIN fs2_industries ind on (ind.id = cat_ind.industry_id)"
        
    sql += " where"
    sql += " s_k.id in (#{skill_ids})"
    
    
    skills = Fs2SkillsProfile.connection.execute(sql)
    
    skill_index = 0
    returned_fs_profile = {}
    returned_fs_profile[:skills] = []
    returned_fs_profile[:_lists] = {
      :industries => [],
      :categories => [],
      :skills => [],
      :related_strong => [],
      :related_some => []
    }
    
    # Benchmark.bm do |x|
      # x.report("_find_by") { fs_profile_skills = Fs2SkillsProfile.find_by_sql(sql) }
      
      # --- x3 FASTER
      # x.report("_execute") { fs_profile_skills = Fs2SkillsProfile.connection.execute(sql) }
    # end
    
    
    # Iterate over results
    # -- Results will have multiple rows for each skills_profile (holding the complex 'primary skills, subskills' etc)
    skills.each do |skill|


      # -- X - SKILL INFO
      
      returned_fs_profile[:skills][skill_index] = {
        :skill => [ skill[4].to_i, skill[5] ],
        :years_exp => params['skills_profile'][skill_index][:yrs_exp].to_i,
        :priority => skill_index + 1,
        :related_strong => [],
        :related_some => []
      }
      returned_fs_profile[:skills][skill_index][:industry] = [ skill[0].to_i, skill[1] ] if skill[0]
      returned_fs_profile[:skills][skill_index][:category] = [ skill[2].to_i, skill[3] ] if skill[2]
      
      
      # -- X - RELATED
      
      if skill[6] && !skill[6].empty? && skill[8] && !skill[8].empty? && skill[7] && !skill[7].empty?
        
          ids = skill[6].split(",")
          names = skill[7].split(",")
          strengths = skill[8].split(",")
          
          ids.each_index do |ei|
            if strengths[ei].to_i == 2 # Strong
              returned_fs_profile[:skills][skill_index][:related_strong] << [ ids[ei], names[ei] ]
            elsif strengths[ei].to_i == 3 # Some
              returned_fs_profile[:skills][skill_index][:related_some] << [ ids[ei], names[ei] ]
            end
          end
          
      end
      
      
      # -- X - _LISTS
      
      returned_fs_profile[:_lists][:industries] << returned_fs_profile[:skills][skill_index][:industry]
      returned_fs_profile[:_lists][:categories] << returned_fs_profile[:skills][skill_index][:category]
      returned_fs_profile[:_lists][:skills] << returned_fs_profile[:skills][skill_index][:skill]
      returned_fs_profile[:_lists][:related_strong] << returned_fs_profile[:skills][skill_index][:related_strong]
      returned_fs_profile[:_lists][:related_some] << returned_fs_profile[:skills][skill_index][:related_some]
      
      
      skill_index += 1
      
    end # 'skill' iteration
    
    
    @request_fs_profile = returned_fs_profile
    
  end
  
  
  
  def ___create_db_ready_fs_profile
    
    return if params['skills_profile'].nil?
    
    # Skill names
    @skills = Array.new
    
    5.times do |i|
      
      # Skill names
      if params['skills_profile'][i] && params['skills_profile'][i][:id].to_i != -1
        
        @skills[i] = Fs2Skill.new
        @skills[i].priority = i + 1
        @skills[i].keyword_id = @request_fs_profile[:skills][i][:skill][0]
        @skills[i].years_experience = @request_fs_profile[:skills][i][:years_exp][0]

      end
    end
    
    @skills
    
  end
  
  
  
  
  # ***************************************
  #  FILTERS
  # ***************************************
  
  #
  # The following method works with an already prepared array of 'keyword ids'
  # 
  # This action is invoked when an 'ajax' call is made for the following actions:
  # - 'save profile'
  # - 'search' (either jobs or job seekers)
  #
  def create_fs_profile_from_request
    
    return if params['skills_profile'].nil?
    
    @request_fs_profile = Hash.new
    @request_fs_profile[:skill_names_ids_map] = Hash.new
    @request_fs_profile[:skill_ids_matrix] = Array.new
    @request_fs_profile[:skill_names_matrix] = Array.new
    
    
    i = 0
    
    while params['skills_profile'][i] do
    # 5.times do |i|
    
      @request_fs_profile[:skill_ids_matrix][i] = [-1, -1, nil]
      @request_fs_profile[:skill_names_matrix][i] = ["", "", Array.new(0)]
      
      # if params['skills_profile'][i]
        
        # ----- Keyword matrix - Skill names
        if params['skills_profile'][i][:value] && !params['skills_profile'][i][:value].blank? && params['skills_profile'][i][:id].to_i > 0
          @request_fs_profile[:skill_ids_matrix][i][0] = params['skills_profile'][i][:id].to_i
          @request_fs_profile[:skill_names_matrix][i][0] = params['skills_profile'][i][:value]
          @request_fs_profile[:skill_names_ids_map][params['skills_profile'][i][:value]] = params['skills_profile'][i][:id]
          # @skills_profile_keywords.push(@skills_profile_matrix[@skill_key][:name])
        end
        
        # ----- Keyword matrix - Years experience
        @request_fs_profile[:skill_ids_matrix][i][1] = params['skills_profile'][i][:yrs_exp].to_i
        @request_fs_profile[:skill_names_matrix][i][1] = params['skills_profile'][i][:yrs_exp]
        
        # ----- Keyword matrix - Skill details
        if params['skills_profile'][i][:sub_skills] && params['skills_profile'][i][:sub_skills].length > 0
          @request_fs_profile[:skill_ids_matrix][i][2] = Array.new(0)
          skill_detail_keywords = params['skills_profile'][i][:sub_skills]
          
          skill_detail_keywords.each_index do |sub_skill_index|
            if skill_detail_keywords[sub_skill_index][:value] && !skill_detail_keywords[sub_skill_index][:value].blank? && skill_detail_keywords[sub_skill_index][:id].to_i > 0
              @request_fs_profile[:skill_ids_matrix][i][2][sub_skill_index] = skill_detail_keywords[sub_skill_index][:id].to_i
              @request_fs_profile[:skill_names_matrix][i][2][sub_skill_index] = skill_detail_keywords[sub_skill_index][:value]
              @request_fs_profile[:skill_names_ids_map][skill_detail_keywords[sub_skill_index][:value]] = skill_detail_keywords[sub_skill_index][:id]
              # @skills_profile_keywords.push(@skills_profile_matrix[@skill_key][:details][sub_skill_index])  
            end
          end
        end
        
        i += 1
      # end
    end
      
    @request_fs_profile
      
  end    
  
  def create_db_ready_fs_profile
    
    return if params['skills_profile'].nil?
    
    # Skill names
    @skills = Array.new
    # @additional_requirements = Array.new
    
    5.times do |i|
      
      # Skill names
      if params['skills_profile'][i] && params['skills_profile'][i][:id].to_i != -1
        
        @skills[i] = Fs2Skill.new
        @skills[i].priority = i + 1
        @skills[i].keyword_id = @request_fs_profile[:skill_ids_matrix][i][0]
        @skills[i].years_experience = @request_fs_profile[:skill_ids_matrix][i][1]
        
        # @skills_profile_ids_and_numbers[@skill_key][:name] = @skills[i].keyword_id
        # @skills_profile_ids_and_numbers[@skill_key][:years_experience] = @skills[i].years_experience
        
        # Skill details
        if @request_fs_profile[:skill_ids_matrix][i][2] && !@request_fs_profile[:skill_ids_matrix][i][2][0].blank?
          @request_fs_profile[:skill_ids_matrix][i][2].each_index do |keyword_index|
            
            current_detail_keyword = @request_fs_profile[:skill_ids_matrix][i][2][keyword_index]
            # @skills_profile_ids_and_numbers[@skill_key][:details][keyword_index] = @keywords_hash[@current_detail_keyword] 
    
            if current_detail_keyword && !current_detail_keyword.blank?
              @skills[i].skill_details.build(:attributes => {
                :priority => keyword_index + 1,
                :keyword_id => current_detail_keyword})
            end
            
          end
        end
      end
    end
    
    # if !@skills_profile_matrix[:additional_requirements][0].blank?
#       
      # # 3. Create the 'additional requirements' object
      # @skills_profile_matrix[:additional_requirements].each_index do |keyword_index|
#         
        # @skills_profile_ids_and_numbers[:additional_requirements][keyword_index] = 
          # @keywords_hash[@skills_profile_matrix[:additional_requirements][keyword_index]]
#         
        # @additional_requirements[keyword_index] = Fs2AdditionalRequirement.new
        # @additional_requirements[keyword_index].priority = keyword_index + 1
        # @additional_requirements[keyword_index].keyword_id = 
          # @keywords_hash[@skills_profile_matrix[:additional_requirements][keyword_index]]
# 
      # end
    # end
    
    @skills
    
  end
  
  def get_job_application(job_seeker_id, job_id)
    # First, get the 'skills_profile' for the job_seeker
    job_seeker_fs_profiles = fetch_skills_profiles({:job_seeker_id => job_seeker_id})
    job_fs_profiles = fetch_skills_profiles({:job_id => job_id})
    job_application = nil
    
    active_job_seeker_fs_profile = job_seeker_fs_profiles[job_seeker_fs_profiles[:info][:active_fs_profile_id]]
    active_job_fs_profile = job_fs_profiles[job_fs_profiles[:info][:active_fs_profile_id]]
    
    if active_job_seeker_fs_profile && active_job_fs_profile
      job_application = Fs2JobApplication.find(
        :first, 
        :conditions => ["job_seeker_fs_profile_id = ? AND job_fs_profile_id = ?", 
          active_job_seeker_fs_profile[:id], active_job_fs_profile[:id]])
    end
    
    {:job_application => job_application,
      :job_seeker_fs_profile => active_job_seeker_fs_profile,
      :job_fs_profile => active_job_fs_profile}
  end
  
  def set_active_fs_profile
    if @fs_profiles && @fs_profiles[:info] && @fs_profiles[@fs_profiles[:info][:active_fs_profile_id]][:skill_names_matrix]
      @active_fs_profile = @fs_profiles[@fs_profiles[:info][:active_fs_profile_id]]
    end
  end  
  
  
  
  def ___fetch_skills_profiles(filters = {}, by = {})
    
    # -- 1 - SIMPLIFIED form - only by skill
    
    sql = "select DISTINCT" +
      " sp.id sp_id, sp.label sp_label, sp.profile_type, sp.updated_at," +
      " ind.id industry_id, ind.name industry_name," +
      " cat.id category_id, cat.category_name," +
      " s.keyword_id s_kid, s_k.keyword skill_name," +
      " s.priority sp, s.years_experience," +
      " group_concat(related.related_skill_id order by related.related_skill_id asc separator ',') rel_skills_ids," +
      " group_concat(rel_keyword.keyword order by related.related_skill_id asc separator ',') rel_skills_names," +
      " group_concat(related.related_strength order by related.related_skill_id asc separator ',') rel_skills_strength," +
      " sp.entity_type, sp.entity_id"
      
    sql += 
      " from fs2_skills_profiles sp"
    
    sql += 
      " LEFT JOIN fs2_skills s on (sp.id = s.skills_profile_id)" +
      " LEFT JOIN fs2_keywords s_k on (s.keyword_id = s_k.id)" +
      " LEFT JOIN fs2_skills_related related on (related.skill_id = s.keyword_id)" +
      " LEFT JOIN fs2_keywords rel_keyword on (rel_keyword.id = related.related_skill_id)" + 
      " LEFT JOIN fs2_map_skill_to_category skill_cat on (s.keyword_id = skill_cat.skill_id) " +
      " LEFT JOIN fs2_skill_categories cat on (cat.id = skill_cat.skill_category_id)" + 
      " LEFT JOIN fs2_map_category_to_industry cat_ind on (cat_ind.category_id = skill_cat.skill_category_id)" + 
      " LEFT JOIN fs2_industries ind on (ind.id = cat_ind.industry_id)"
        
    sql += " where"
    sql += " sp.id = " + by[:skills_profile_id].to_s + " AND" if by[:skills_profile_id]
    
    sql += " sp.profile_type = 1 AND" if filters[:profile_type] && filters[:profile_type] == 'user_profile'
    sql += " sp.entity_type = 1 AND" if filters[:entity_type] && filters[:entity_type] == 'job_seeker'
    
    sql += " s.keyword_id > 0 and s.priority < 6"
      
    sql += " group by sp.id, sp"
    sql += " order by sp.id asc, sp asc"
    
    
    fs_profile_skills = Fs2SkillsProfile.connection.execute(sql)
    # Benchmark.bm do |x|
      # x.report("_find_by") { fs_profile_skills = Fs2SkillsProfile.find_by_sql(sql) }
      
      # --- x3 FASTER
      # x.report("_execute") { fs_profile_skills = Fs2SkillsProfile.connection.execute(sql) }
    # end


    returned_fs_profiles = {} if fs_profile_skills
    fs_profiles_counter = 0
    skill_index = 0
    prev_fs_profile_id = nil
    
    # Iterate over results
    # -- Results will have multiple rows for each skills_profile (holding the complex 'primary skills, subskills' etc)
    fs_profile_skills.each_hash do |skill|
      
      
      # -- X - INITIALIZE FS_PROFILE
      
      if !prev_fs_profile_id || skill['sp_id'] != prev_fs_profile_id
        
        fs_profiles_counter += 1
        skill_index = 0
      
        returned_fs_profiles[skill['sp_id']] = Hash.new
        returned_fs_profiles[skill['sp_id']][:label] = skill['sp_label']
        returned_fs_profiles[skill['sp_id']][:id] = skill['sp_id']
        returned_fs_profiles[skill['sp_id']][:updated_at] = skill['updated_at']
        returned_fs_profiles[skill['sp_id']][:skills] = []
        returned_fs_profiles[skill['sp_id']][:_lists] = {
          :industries => [],
          :categories => [],
          :skills => [],
          :related_strong => [],
          :related_some => []
        }
          
      end


      # -- X - SKILL INFO
      
      returned_fs_profiles[skill['sp_id']][:skills][skill_index] = {
        :skill => [ skill['s_kid'].to_i, skill['skill_name'] ],
        :years_exp => skill['years_experience'].to_i,
        :priority => skill['sp'].to_i,
        :industry => [ skill['industry_id'].to_i, skill['industry_name'] ],
        :category => [ skill['category_id'].to_i, skill['category_name'] ],
        :related_strong => [],
        :related_some => []
      }
      
      
      # -- X - RELATED
      
      if skill['rel_skills_ids'] && !skill['rel_skills_ids'].empty? &&
        skill['rel_skills_strength'] && !skill['rel_skills_strength'].empty? &&
        skill['rel_skills_names'] && !skill['rel_skills_names'].empty?
        
          ids = skill['rel_skills_ids'].split(",")
          names = skill['rel_skills_names'].split(",")
          strengths = skill['rel_skills_strength'].split(",")
          
          ids.each_index do |ei|
            if strengths[ei].to_i == 2 # Strong
              returned_fs_profiles[skill['sp_id']][:skills][skill_index][:related_strong] << [ ids[ei], names[ei] ]
            elsif strengths[ei].to_i == 3 # Some
              returned_fs_profiles[skill['sp_id']][:skills][skill_index][:related_some] << [ ids[ei], names[ei] ]
            end
          end
      end
      
      
      # -- X - _LISTS
      
      returned_fs_profiles[skill['sp_id']][:_lists][:industries] << returned_fs_profiles[skill['sp_id']][:skills][skill_index][:industry]
      returned_fs_profiles[skill['sp_id']][:_lists][:categories] << returned_fs_profiles[skill['sp_id']][:skills][skill_index][:category]
      returned_fs_profiles[skill['sp_id']][:_lists][:skills] << returned_fs_profiles[skill['sp_id']][:skills][skill_index][:skill]
      returned_fs_profiles[skill['sp_id']][:_lists][:related_strong] << returned_fs_profiles[skill['sp_id']][:skills][skill_index][:related_strong]
      returned_fs_profiles[skill['sp_id']][:_lists][:related_some] << returned_fs_profiles[skill['sp_id']][:skills][skill_index][:related_some]


      # -- X - SUMMARY & ACTIVE PROFILE
      
      returned_fs_profiles[:_active] = skill['sp_id']
      returned_fs_profiles[:_total] = fs_profiles_counter
      
      
      skill_index += 1
      prev_fs_profile_id = skill['sp_id']
      
    end # 'skill' iteration
    
    returned_fs_profiles

  end  
  
  # by
  # - :skills_profile_id
  # - :job_seeker_id
  # - :job_id
  #
  # what
  # - :template
  # - :search
  # - :demo  
  #
  def fetch_skills_profiles(by = {}, what = {})
    
    if by.empty?
      flash[:error] = "Can't find 'skills_profile' without 'by'!"
      return
    end
    
    # -- 1 - SIMPLIFIED form - only by skill
    
    sql = "select " +
      "sp.id sp_id, sp.entity_id, sp.label sp_label, sp.entity_type, sp.profile_type, sp.updated_at, " + 
      "s.keyword_id s_kid, s_k.keyword s_keyword, " +  
      "s.priority sp, s.years_experience, " + 
      "cat.category_name, ind.name industry_name"
      
    sql += 
      " from fs2_skills_profiles sp LEFT JOIN "
    
    sql += 
      "fs2_skills s on (sp.id = s.skills_profile_id) LEFT JOIN " +
      "fs2_keywords s_k on (s.keyword_id = s_k.id)" + 
      " LEFT JOIN fs2_map_skill_to_category skill_cat on (s.keyword_id = skill_cat.skill_id)" +
      " LEFT JOIN fs2_skill_categories cat on (cat.id = skill_cat.skill_category_id)" + 
      " LEFT JOIN fs2_map_category_to_industry cat_ind on (cat_ind.category_id = skill_cat.skill_category_id)" +
      " LEFT JOIN fs2_industries ind on (ind.id = cat_ind.industry_id)" +
    " where "
    
    # -- 2 - COMPLEX - The following is the query for selecting all elements including 'skills, details and additional requirements'
    
    # sql = "select " +
      # "sp.id sp_id, sp.entity_id, sp.label sp_label, sp.entity_type, sp.profile_type, sp.updated_at, " + 
      # "s.keyword_id s_kid, s_k.keyword s_keyword, " +  
      # "s.priority sp, s.years_experience, s.self_rate, " + 
      # "sd.keyword_id sd_kid, sd_k.keyword sd_keyword, sd.priority sdp, " + 
      # "ar.keyword_id ar_kid, ar_k.keyword ar_keyword, ar.priority arp " +
#        
    # "from fs2_skills_profiles sp LEFT JOIN "
#     
    # sql += 
      # "fs2_skills s on (sp.id = s.skills_profile_id) LEFT JOIN " +
      # "fs2_keywords s_k on (s.keyword_id = s_k.id) LEFT JOIN " + 
      # "fs2_skill_details sd on (s.id = sd.skill_id) LEFT JOIN " +
      # "fs2_keywords sd_k on (sd.keyword_id = sd_k.id) LEFT JOIN " + 
      # "fs2_additional_requirements ar on (sp.id = ar.skills_profile_id) LEFT JOIN " +
      # "fs2_keywords ar_k on (s.keyword_id = ar_k.id) " + 
    # "where "
    
    if by[:skills_profile_id]
      
      sql += "sp.id = " + by[:skills_profile_id].to_s
      
      if what[:template]
        sql += " and sp.profile_type = " + FsBaseController::FS_PROFILE_TYPES[:template].to_s
      elsif what[:search]
        sql += " and sp.profile_type = " + FsBaseController::FS_PROFILE_TYPES[:search].to_s
      elsif what[:demo]
        sql += " and sp.profile_type = " + FsBaseController::FS_PROFILE_TYPES[:demo].to_s
      end
      
    elsif by[:job_seeker_id] || by[:job_id]
      
      sql += "sp.profile_type = " + FsBaseController::FS_PROFILE_TYPES[:user_profile].to_s
      
      if by[:job_seeker_id]
          sql += " and sp.entity_type = " + FsBaseController::ENTITY_TYPES[:job_seeker].to_s +
          " and sp.entity_id = " + by[:job_seeker_id].to_s
      elsif by[:job_id] 
          sql += " and sp.entity_type = " + FsBaseController::ENTITY_TYPES[:job].to_s +
          " and sp.entity_id = " + by[:job_id].to_s
      end
          
    end
    
    # 'ORDER BY'
    sql += " order by sp.updated_at asc, sp_id asc"
    
    skills_profiles = Fs2SkillsProfile.find_by_sql(sql)
    returned_fs_profiles = { :info => {}} if skills_profiles && skills_profiles[0]
    prev_fs_profile_id = nil    
    fs_profiles_counter = 0
    
    # Iterate over results
    # -- Results will have multiple rows for each skills_profile (holding the complex 'primary skills, subskills' etc)
    skills_profiles.each do |skills_profile|
      
      
      # -- X - INITIALIZE FS_PROFILE
      
      if !prev_fs_profile_id || skills_profile.sp_id != prev_fs_profile_id
        
        fs_profiles_counter += 1
      
        returned_fs_profiles[skills_profile.sp_id] = Hash.new
        returned_fs_profiles[skills_profile.sp_id][:label] = skills_profile.sp_label
        returned_fs_profiles[skills_profile.sp_id][:id] = skills_profile.sp_id
        returned_fs_profiles[skills_profile.sp_id][:updated_at] = skills_profile.updated_at
        returned_fs_profiles[skills_profile.sp_id][:skill_names_ids_map] = Hash.new if by[:create_keywords_hash]
        
        returned_fs_profiles[skills_profile.sp_id][:skill_ids_matrix] = Array.new
        returned_fs_profiles[skills_profile.sp_id][:skill_names_matrix] = Array.new
        
        
        # -- X - NEW STRUCTURE -> clearer
        
        returned_fs_profiles[skills_profile.sp_id][:skills] = Array.new
          
      end


      # -- X - PRIORITIES
      
      js_skill_priority = skills_profile[:sp].to_i
      js_skill_detail_priority = skills_profile.sdp.to_i if !skills_profile[:sdp].nil?
      js_additional_requirements_priority = skills_profile.arp.to_i if !skills_profile[:arp].nil?
        
      
      # -- X - INITIALIZE SINGLE SKILL
      
      returned_fs_profiles[skills_profile.sp_id][:skill_ids_matrix][js_skill_priority - 1] = [-1, -1, nil]
      returned_fs_profiles[skills_profile.sp_id][:skill_names_matrix][js_skill_priority - 1] = ["", "", Array.new(0)]
          
        
      # -- X - SKILLS
      
      if !skills_profile[:sp].nil?
        if returned_fs_profiles[skills_profile.sp_id][:skill_ids_matrix][js_skill_priority - 1][0] == -1
          returned_fs_profiles[skills_profile.sp_id][:skill_ids_matrix][js_skill_priority - 1][0] = skills_profile.s_kid.to_i
          returned_fs_profiles[skills_profile.sp_id][:skill_names_matrix][js_skill_priority - 1][0] = skills_profile.s_keyword
          returned_fs_profiles[skills_profile.sp_id][:skill_names_ids_map][skills_profile.s_keyword] = skills_profile.s_kid.to_i if by[:create_keywords_hash]
          
          returned_fs_profiles[skills_profile.sp_id][:skill_ids_matrix][js_skill_priority - 1][1] = skills_profile.years_experience.to_i
          returned_fs_profiles[skills_profile.sp_id][:skill_names_matrix][js_skill_priority - 1][1] = skills_profile.years_experience.to_i
        end
      end      
      
      
      # -- X - DETAIL (previous 5skills profile, more detailed fine-grained skills)
      
      if !skills_profile[:sdp].nil?
        if !returned_fs_profiles[skills_profile.sp_id][:skill_ids_matrix][js_skill_priority - 1][2]
          returned_fs_profiles[skills_profile.sp_id][:skill_ids_matrix][js_skill_priority - 1][2] = Array.new(0)
        end
        
        # ASSUMPTION: Duplicates are consistent, don't need to check if a value already exists, just override
        if !js_skill_detail_priority.nil? && !skills_profile.sd_kid.nil?
          returned_fs_profiles[skills_profile.sp_id][:skill_ids_matrix][js_skill_priority - 1][2][js_skill_detail_priority - 1] = skills_profile.sd_kid.to_i
          returned_fs_profiles[skills_profile.sp_id][:skill_names_matrix][js_skill_priority - 1][2].push(skills_profile.sd_keyword)
          returned_fs_profiles[skills_profile.sp_id][:skill_names_ids_map][skills_profile.sd_keyword] = skills_profile.sd_kid.to_i if by[:create_keywords_hash]
        end
      end
      
      
      # -- X - ADDITIONAL REQUIREMENTS (salary etc)
      
      if !skills_profile[:arp].nil?
        if !returned_fs_profiles[skills_profile.sp_id][:skill_ids_matrix][7] 
          returned_fs_profiles[skills_profile.sp_id][:skill_ids_matrix][7] = Array.new(0)
        end
        
        # ASSUMPTION: Duplicates are consistent, don't need to check if a value already exists, just override
        if !js_additional_requirements_priority.nil? && !skills_profile.ar_kid.nil?
          returned_fs_profiles[skills_profile.sp_id][:skill_ids_matrix][7][js_additional_requirements_priority - 1] = skills_profile.ar_kid.to_i
          returned_fs_profiles[skills_profile.sp_id][:skill_names_matrix][7].push(skills_profile.ar_keyword)
          returned_fs_profiles[skills_profile.sp_id][:skill_names_ids_map][skills_profile.ar_keyword] = skills_profile.ar_kid.to_i if by[:create_keywords_hash]
        end
      end


      # -- X - SUMMARY & ACTIVE PROFILE
      
      returned_fs_profiles[:info][:active_fs_profile_id] = skills_profile.sp_id
      returned_fs_profiles[:info][:number_of_profiles] = fs_profiles_counter
      
      
      prev_fs_profile_id = skills_profile.sp_id
      
    end # 'skills_profiles' iteration
    
    # return the found skills profiles
    returned_fs_profiles

  end
  
  
  # -- 
  #
  # 'job_id' - can be either (1) a DB job_id or a (2) 'job_ref_key' for tracking posts (determined by the 'by_job_ref_key' flag)
  #
  def fetch_job_profile(
      job_id, 
      match_with_job_seeker_id = nil, 
      flags = {:include_skills_profile => true, :include_publishing_post_info => false})
    
    returned_job = Hash.new
      
    # --- Grab the job from the database
    sql = "select " +
     "j.id, j.title, j.description, j.company_id, j.agency_id, j.company_contact_id, j.agency_contact_id, j.teaser, " +
     "c.name company_name, c.phone company_phone, c.email company_email, " +  
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
    
    db_jobs = Fs2Job.find_by_sql(sql)
    db_job_obj = clean_attributes(db_jobs[0]) if db_jobs && db_jobs[0]
    

    # Create the 'job' object
    if db_job_obj
      returned_job[:job_obj] = Fs2Job.new({
        :title => db_job_obj[:title],
        :description => db_job_obj[:description],
        :company_id => db_job_obj[:company_id],
        :agency_id => db_job_obj[:agency_id],
        :teaser => db_job_obj[:teaser],
        :company_contact_id => db_job_obj[:company_contact_id],
        :agency_contact_id => db_job_obj[:agency_contact_id]}) {
          |job| job.id = db_job_obj[:id]
        }
        
      returned_job[:fs_profiles] = fetch_skills_profiles({:job_id => db_job_obj[:id]}) if flags && flags[:include_skills_profile] && flags[:include_skills_profile] == true
      
      
      # --- COMPANY
      
      returned_job[:company_obj] = Fs2Organisation.new({
        :name => db_job_obj[:company_name],
        :phone => db_job_obj[:company_phone],
        :email => db_job_obj[:company_email]
      }) {
        |company| company.id = db_job_obj[:company_id]
      }
      returned_job[:company_files] = fetch_files(db_job_obj[:company_id], [Fs2File::FILE_TYPES[:company_logo]])
      returned_job[:company_contact_obj] = Fs2Contact.new({:full_name => db_job_obj[:cc_full_name]})
      returned_job[:company_contact_user_obj] = Fs2User.new({:email => db_job_obj[:cu_email]}) {
        |c_user| c_user.id = db_job_obj[:cu_id]
      }
      
      
      # --- AGENCY
      
      returned_job[:agency_obj] = Fs2Organisation.new({
        :name => db_job_obj[:a_name]
      })  {
        |agency| agency.id = db_job_obj[:agency_id]
      }
      returned_job[:agency_files] = fetch_files(db_job_obj[:agency_id], [Fs2File::FILE_TYPES[:agency_logo]])
      returned_job[:agency_contact_obj] = Fs2Contact.new({:full_name => db_job_obj[:ac_full_name]})
      returned_job[:agency_contact_user_obj] = Fs2User.new({:email => db_job_obj[:au_email]}) {
        |a_user| a_user.id = db_job_obj[:au_id]
      }
      
      # If a match with a job is requested
      if match_with_job_seeker_id
        # Perform the 'entity' search with the specified 'job_seeker_id'
        # I.e. perform a search based on the provided 'fs_profile' (the Job's one) against a specific Job seeker
        returned_job[:job_seeker_match] = search_entity_2(
        {
          :request_fs_profile => returned_job[:fs_profiles][returned_job[:fs_profiles][:info][:active_fs_profile_id]], 
          :match_with_job_seeker_id => match_with_job_seeker_id
        }, { 
          :entity_type => ENTITY_TYPES[:job_seeker]
        })
      
        
        # Use the 'search' / 'request' 'matches_ids_matrix' (the Job's one).
        # The Job's matching information should be highlighted 
        returned_job[:fs_profiles][returned_job[:fs_profiles][:info][:active_fs_profile_id]][:skill_ids_matches_matrix] = returned_job[:job_seeker_match][1][:fs_search_match_ids_matrix]
      end
    end
    
    returned_job
    
  end
  
  # 
  # This method matches the job seeker's 'ACTIVE' fs_profile with the 'job_id' active fs_profile
  #
  def _match_job_seeker(job_seeker_id, job_id)
    return nil if job_seeker_id.nil? or job_id.nil?
    
    js_fs_profiles = fetch_skills_profiles({:job_seeker_id => job_seeker_id})
    
    job_match = search_entity_2({
          :request_fs_profile => js_fs_profiles[js_fs_profiles[:info][:active_fs_profile_id]],
          :match_with_job_id => job_id
        }, {
          :entity_type => ENTITY_TYPES[:job]
        })
        
    {:job_match => job_match, 
      :fs_profiles => js_fs_profiles,
      :active_fs_profile => js_fs_profiles[js_fs_profiles[:info][:active_fs_profile_id]]}
  end
  
  def _match_job(job_id, job_seeker_id)
    js_fs_profile = fetch_skills_profiles
  end
  
  def fetch_job_seeker_profile(job_seeker_id, match_with_job_id = nil, flags = {:include_skills_profile => true})
    
    returned_job_seeker = Hash.new
    
    # Create the 'job_seeker' object
    returned_job_seeker[:job_seeker_obj] = Fs2JobSeeker.find_by_id(job_seeker_id)
    returned_job_seeker[:user_obj] = Fs2User.find_by_id(returned_job_seeker[:job_seeker_obj].user_id) if returned_job_seeker[:job_seeker_obj].user_id
    returned_job_seeker[:fs_profiles] = fetch_skills_profiles({:job_seeker_id => returned_job_seeker[:job_seeker_obj].id}) if flags && flags[:include_skills_profile] && flags[:include_skills_profile] == true
    returned_job_seeker[:files] = fetch_files(returned_job_seeker[:job_seeker_obj].id, [Fs2File::FILE_TYPES[:profile_photo], Fs2File::FILE_TYPES[:cv]], returned_job_seeker[:job_seeker_obj].anonymous)
    
    # If a match with a job is requested
    if match_with_job_id
      # Perform the 'entity' search with the specified 'job_id'
      # I.e. perform a search based on the provided 'fs_profile' (the Job seeker's one) against a specific Job
      returned_job_seeker[:job_match] = search_entity_2(
        {
          :request_fs_profile => returned_job_seeker[:fs_profiles][returned_job_seeker[:fs_profiles][:info][:active_fs_profile_id]],
          :match_with_job_id => match_with_job_id
        }, {
          :entity_type => ENTITY_TYPES[:job]
        })
      
      # Use the 'search' / 'request' 'matches_ids_matrix' (the Job seeker's one).
      # The Job seeker's matching information should be highlighted 
      returned_job_seeker[:fs_profiles][returned_job_seeker[:fs_profiles][:info][:active_fs_profile_id]][:skill_ids_matches_matrix] = returned_job_seeker[:job_match][1][:fs_search_match_ids_matrix]
    end
    
    returned_job_seeker 
    
  end
  
  
  
  # --- AJAX CALLS
  
  def ajax_search_organizations
    js_organizations = db_search_organizations
    
    respond_to do |format|
      
      format.json {
        @arr = {
            :status => "200",
            :action => "search_organizations",
            :results => js_organizations
          }
          
        render :json => @arr.to_json, :callback => params[:callback] 
      }
      
    end    
  end

  def db_search_organizations
    @results_organizations = Fs2Organisation.find(
      :all, 
      :limit => 15,
      :order => "name ASC",
      :conditions => ["name LIKE ?", "%#{params['organization_name']}%"])
    
    return if @results_organizations.nil?
    
    js_organizations = Array.new
    
    @results_organizations.each do |organization|
      type_name = "Agency" if organization.organisation_type == Fs2Organisation::ORGANISATION_TYPES[:agency]
      type_name = "Company" if organization.organisation_type == Fs2Organisation::ORGANISATION_TYPES[:company]
      
      js_organizations << {
        :id => organization.id,
        :value => organization.name,
        :jobs_email => organization.email,
        :type => organization.organisation_type,
        :type_name => type_name
        
      }
    end
    
    js_organizations
  end    
  
  def ajax_search_skills
    db_search_skills
    
    respond_to do |format|
      
      format.json {
        @arr = {
            :status => "200",
            :action => "search_skills",
            :results => @js_skills
          }
          
        render :json => @arr.to_json, :callback => params[:callback] 
      }
      
    end    
  end

  
  # ---
  # This method retrieves the current user from the 
  #
  def ajax_sync

    # -- BASIC setup    
    @arr = {
      :action => "_sync",
      :entities => params[:_sync_entities]
    }

    
    # -- ERROR
    if params[:_sync_entities].nil? || params[:_sync_entities].empty?
      
      @arr = @arr.merge!({
        :status => "50",
        :message => 'Parameter "_sync_entities" not defined!'
      })
      
      
    # --- SUCCESS
    else
      
      
      @arr[:status] = "200"
      
      if params[:_sync_entities][:_demo__job_id]
        job_id = params[:_sync_entities][:_demo__job_id]
      else
        job_id = 164
      end
      @arr[:_demo__job_id] = job_id
      
      # -- Get the JOB object
      @job_profile = fetch_job_profile(job_id)
      
      
      # --- CORE
      #
      # If the client requests '_core', i.e. '_core' == true, the server will return the initialization parameters
      # These parameters need to be sent in each call to authorize the request
      #
      if params[:_sync_entities][:_core] # all
        
        @arr[:_core] = {
          :_fsession_id => '-1',
          :person_type => 'recruiter',
          :person_id => 32,
          :user_id => 642, # -> agency_contact_id = 36 | agency_id = 42 | job_id = 164
        }
        
      end
      
      
      # --- SKELETON
      #
      if params[:_sync_entities][:_skeleton] # all
        
        
        # --- DEMO
      
        if params[:_sync_entities][:_demo__job_id]
          job_id = params[:_sync_entities][:_demo__job_id]
        else
          job_id = 164
        end
        @arr[:_demo__job_id] = job_id
        
        # -- Get the JOB object
        @job_profile = fetch_job_profile(job_id)
        
              
        @arr[:_demo__job__company__logo_url] = @job_profile[:company_files][:company_logo].path
        @arr[:_demo__job__title] = @job_profile[:job_obj].title
      
      end
      
      
      # --- ENTITIES
      #
      # Allow multiple entity updates (hard coded at the moment)
      
      # -- JOB
      if params[:_sync_entities][:job]
          # Sample of 'job' sync
          # @job_profile = fetch_job_profile(job_id)
      end
      
      
      # -- JOB SEEKER --> Results
      
      # The SYNC will provide results based on the information from the Database (A semi-PUSH from the server)
      # > Once the user changes the fs_profile (_dirty), the PULL will occur, forcing the results to refresh
      
      if params[:_sync_entities][:job_seeker]
          @arr[:job_seeker] = params[:_sync_entities][:job_seeker]
          @arr[:job_seeker][:__server] = {}
          
          
          # -------------------- PHASE 2
          
          fs_profile_id = @job_profile[:fs_profiles][:info][:active_fs_profile_id]
          fs_profiles = ___fetch_skills_profiles(
            {:profile_type => 'user_profile', :entity_type => 'job_seeker'},
            {:skills_profile_id => fs_profile_id})
          
          what = ['job_seekers']
          by = { :fs_profile_id => fs_profile_id }
          actions = []
          data = { :fs_profile => fs_profiles[fs_profiles[:_active]] }
          
          @arr[:job_seeker][:__server][:_search_data] = data[:fs_profile]
          @arr[:job_seeker][:__server][:_results] = ___search(what, by, nil, data)
          
          
          # -------------------- PHASE 1
          # fs_profile = fetch_skills_profiles({:skills_profile_id => fs_profile_id}, {})
          
          # -- X - Build the 'fs_profile' object for processing
          #TODO: Need to add support for both a specific ID (custom) or the ACTIVE one (see below '...[:fs_profile]')
              # fs_profile_id = @job_profile[:fs_profiles][:info][:active_fs_profile_id]
              # fs_profile = fetch_skills_profiles({:skills_profile_id => fs_profile_id})
          
          # -- X - Create the flat array of skill_ids
             # skills_profile_a = fs_profile[ fs_profile[:info][:active_fs_profile_id] ][:skill_ids_matrix].collect { |skill_id_matrix| skill_id_matrix[0] }
          
              # what = ['job_seekers']
              # by = { :skill_ids => skills_profile_a.join(",") }
          # filter = { :active => 'past_week', :applied_to_job => true }
          # sort = { :fs_profile_updated => 'desc' }
              # actions = ['match']
          
          # --- For demo usage
          # @fs_results = search_entities_2({:request_fs_profile => @request_fs_profile}, {:entity_type => ENTITY_TYPES[:job_seeker], :include_contact_details => true})
              # _search_entities(what, by)
          
      end
      
      # -- FS_PROFILE
      
      if params[:_sync_entities][:fs_profile]
        
        # Setup the default response object
        @arr[:fs_profile] = params[:_sync_entities][:fs_profile]
        fs_profile_id = nil
        
        # Fetch the fs_profile object
        if params[:_sync_entities][:fs_profile][:id] == 'active' # by ACTIVE
          fs_profile_id = @job_profile[:fs_profiles][:info][:active_fs_profile_id]
        else # by ID
          fs_profile_id = params[:_sync_entities][:fs_profile][:id].to_i
        end
        fs_profile = fetch_skills_profiles({:skills_profile_id => fs_profile_id})
        
        @arr[:fs_profile][:__server] = fs_profile[ fs_profile[:info][:active_fs_profile_id] ]
        
      end
      
      # -- NOTIFICATION
      if params[:_sync_entities][:notification] # job
        
        # Setup the default response object
        @arr[:notification] = params[:_sync_entities][:notification]
            
        # Sample of 'job' sync
        @arr[:notification][:__server] = {
          :updated_at => Time.new.to_time
        }
        
        # JOB APPLICATIONS
        # - Query the 'fs2_user_notifications' table for entity 'job_applications'
        job_app_notification = Fs2UserNotification.find(
          :all,
          :conditions => ["user_id = ? AND entity_name = ? AND seen_datetime IS NULL", params[:_header][:user_id], 'job_application'])
          
        if job_app_notification && !job_app_notification.empty?
          @arr[:notification][:__server][:job_applications] = {
            :_total => job_app_notification.size,
            :_data => job_app_notification.collect { |e| e.attributes }
          }
        else
          @arr[:notification][:__server][:job_applications] = {
            :_total => 0,
            :_data => nil
          }
        end
      end
      
    end
    
    
    respond_to do |format|
      
      format.json {  
        render :json => @arr.to_json, :callback => params[:callback] 
      }
      
    end    
  end


  def db_search_skills
    @results_skills = Fs2Keyword.find(
      :all, 
      :limit => 50,
      :order => "keyword ASC",
      :conditions => ["keyword LIKE ?", "%#{params['skill_name']}%"])
      
    # @results_skills = Fs2SkillKeyword.find(
      # :all, 
      # :limit => 15,
      # :order => "en_US ASC",
      # :conditions => ["en_US LIKE ?", "%#{params['skill_name']}%"])
    
    return if @results_skills.nil?
    
    @js_skills = Array.new
    
    @results_skills.each do |skill|
      @js_skills << {
        :id => skill.id,
        :value => skill.keyword
      }
    end
  end  
  
  
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
    
    # -------------------------------------------------------------
    # @keywords - holds all 'keyword ids' of the keyword names entered in the 5skills profile
    # @existing_keywords_hash - holds 'keyword_name' -> 'keyword_id' mapping of all entered keywords
    # @keywords_hash - holds the COMPLETE hash of 'keyword_name' -> 'keyword_id', including new assigned keyword_ids
    # @skills_profile_keywords - is an 'ARRAY' of all keyword names entered in the profile
    # ------------------------------------------------------------- 

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
    @fs_profile = prep_skills_profile({:template_id => params[:template_id]})
    
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
            :skills_profile_matrix => @fs_profile[:skills_profile_matrix]
          }
          
        end
      
        render :json => @arr.to_json, :callback => params[:callback]
      }
    end
  end
  
  # ***************************************
  #  JOB SEEKER
  # ***************************************
  
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
  
  
  # -- 
  # user_id -> user's id
  # member_types -> ["owner", "member", "awaiting-confirmation"]
  #
  def fetch_publishing_channels(user_id, member_types = ["owner", "member"])
    user_groups = Fs2MapUserToPublishingChannel.find(
      :all,
      :joins => ["LEFT JOIN `fs2_publishing_channels` ON fs2_publishing_channels.channel_id = fs2_map_user_to_publishing_channels.publishing_channel_id"],
      :select => "DISTINCT fs2_publishing_channels.*, fs2_map_user_to_publishing_channels.channel_status", 
      :conditions => ["fs2_map_user_to_publishing_channels.user_id = ? AND fs2_map_user_to_publishing_channels.channel_status IN (?)", user_id.to_s, member_types])
      
   user_groups
  end
  
  def fetch_files(entity_id, a_file_types, is_anonymous = false)
    is_anonymous = false if is_anonymous.nil?
    
    files = Fs2File.find(:all, 
      :conditions => ["entity_id = ? AND file_type IN (?)", entity_id, a_file_types],
      :order => "file_type ASC, updated_at ASC")
    
    if files
      returned_files = Hash.new
      
      files.each do |file|
        
        if is_anonymous == true && file.file_type == Fs2File::FILE_TYPES[:profile_photo]
          returned_files[file.file_type_name] = session[:defaults][:anonymous_profile_photo_file]
        elsif !file.file_type_name.nil?
          returned_files[file.file_type_name] = file
        end
        
      end
    end
    
    returned_files
  end
  
  def clean_attributes(fs_object = nil)
    return if fs_object.nil?
    
    h_attributes = Hash.new
    fs_object.attributes.each {|attribute| h_attributes[attribute[0].to_sym] = fs_object[attribute[0]].to_s}
    
    h_attributes
  end
  
  def render_js_parent(json_s)
    script = 'callbackSuccess(' + json_s + ');'
    
    response.body[0] = script
    
    # We're returning HTML instead of JS or XML now
    response.headers['Content-Type'] = 'text/html; charset=UTF-8'

    # Either pull out a redirect or the request body
    script =  if response.headers['Location']
                #TODO: erase_redirect_results is missing in rails 3.0 has to be implemented
                # erase redirect
                "document.location.href = #{location.to_s.inspect}"
              else
                response.body[0]
              end

    # Escape quotes, linebreaks and slashes, maintaining previously escaped slashes
    # Suggestions for improvement?
    if script
      script = (script || '').
        gsub('\\', '\\\\\\').
        gsub(/\r\n|\r|\n/, '\\n').
        gsub(/['"]/, '\\\\\&').
        gsub('</script>','</scr"+"ipt>')
    end
     
    # Clear out the previous render to prevent double render
    response.request.env['action_controller.instance'].instance_variable_set(:@_response_body, nil)

    # Eval in parent scope and replace document location of this frame
    # so back button doesn't replay action on targeted forms
    # loc = document.location to be set after parent is updated for IE
    # with(window.parent) - pull in variables from parent window
    # setTimeout - scope the execution in the windows parent for safari
    # window.eval - legal eval for Opera
    render :text => "<html><body><script type='text/javascript' charset='utf-8'>
      var loc = document.location;
      with(window.parent) { setTimeout(function() { window.eval('#{script}'); if (typeof(loc) !== 'undefined') loc.replace('about:blank'); }, 1) };
      </script></body></html>"
  end
  
  
  #
  # -- February 2014 version
  #
  # 'h_fields' => 
  #   {'upload_company_logo' => [company's DB organisation id, company_type_id],
  #   'upload_agency_logo' => [agency's DB organisation id, agency_type_id],
  #   'job_seeker__cv' => [job seeker's ID, job_seeker_type_id]}
  #
  # This method uploads the file, stores it in the system
  def _upload_files(h_fields, is_destroy_previous = false)
    uploaded_files = Hash.new
      
    Fs2File.transaction do
      
      h_fields.each do |key, value|
        
        file_type_sym = key.to_s.sub(/(upload_)/, '').to_sym
        
        begin
        
          uploaded_files[file_type_sym] = Fs2File.new(params[key])
          
          if !params[key].nil?
            
            uploaded_files[file_type_sym].entity_id = value[0].to_i if value[0]
            uploaded_files[file_type_sym].entity_type_id = value[1].to_i if value[1]
            uploaded_files[file_type_sym].file_type = Fs2File::FILE_TYPES[file_type_sym]
            
          end
          
          
          # -- Check validity of file upload
          
          if uploaded_files[file_type_sym].valid?
            
            if is_destroy_previous == true && value[0] && value[1]
              Fs2File.connection.execute("delete from fs2_files" + 
                " where entity_id = " + value[0].to_s + 
                " and file_type = " + Fs2File::FILE_TYPES[file_type_sym].to_s + 
                " and entity_type_id = " + value[1].to_s)
            end
            
            # -- X. Check if the file is an image
            
            if uploaded_files[file_type_sym].is_image
              
              
              # -- 1. Calculate the different image sizes
              
              uploaded_files[file_type_sym].original_dimensions = ImageSize.path(uploaded_files[file_type_sym].path).size.join("x")
              uploaded_files[file_type_sym].small_dimensions = uploaded_files[file_type_sym].resize_from_s(Fs2File::IMAGE_JOB_SEEKER_PLACEHOLDER_SIZES[:small])
              uploaded_files[file_type_sym].medium_dimensions = uploaded_files[file_type_sym].resize_from_s(Fs2File::IMAGE_JOB_SEEKER_PLACEHOLDER_SIZES[:medium])
              uploaded_files[file_type_sym].large_dimensions = uploaded_files[file_type_sym].resize_from_s(Fs2File::IMAGE_JOB_SEEKER_PLACEHOLDER_SIZES[:large])
              
              
              # -- 2. Create a WATERMARKED copy of the image
              
              # first_image = MiniMagick::Image.open(uploaded_files[file_type_sym].path)
              # second_image = MiniMagick::Image.open uploaded_files[file_type_sym].path
              # result = first_image.composite(second_image) do |c|
                # c.compose "Over" # OverCompositeOp
                # c.geometry "+20+20" # copy second_image onto first_image from (20, 20)
              # end
              # result.write "public/uploads/output.jpg"
              
            end
            
          end

        rescue => e
          
          flash[:error] += ', Upload failed. Please try again.' if flash[:error]
          flash[:error] = 'Upload failed. Please try again.' if !flash[:error] 
          
        end
      
      end
      
    end
    
    uploaded_files
    
  end  
  
  
  #
  # 'h_fields' => 
  #   {'upload_company_logo' => [company's DB organisation id, company_type_id],
  #   'upload_agency_logo' => [agency's DB organisation id, agency_type_id],
  #   'job_seeker__cv' => [job seeker's ID, job_seeker_type_id]}
  #
  def upload_files(h_fields, is_destroy_previous = false)
    @upload_files = Hash.new if @upload_files.nil?
    is_file_uploaded = true
    
    begin
      
        Fs2File.transaction do
          
          h_fields.each do |key, value|
            file_type_sym = key.to_s.sub(/(upload_)/, '').to_sym
            
            @upload_files[file_type_sym] = Fs2File.new(params[key])
            
            if !params[key].nil?
              if is_destroy_previous == true
                Fs2File.connection.execute("delete from fs2_files" + 
                  " where entity_id = " + value[0].to_s + 
                  " and file_type = " + Fs2File::FILE_TYPES[file_type_sym].to_s + 
                  " and entity_type_id = " + value[1].to_s)
              end
              
              @upload_files[file_type_sym].entity_id = value[0].to_i
              @upload_files[file_type_sym].entity_type_id = value[1].to_i
              @upload_files[file_type_sym].file_type = Fs2File::FILE_TYPES[file_type_sym]
              
              if @upload_files[file_type_sym].is_image
                @upload_files[file_type_sym].original_dimensions = ImageSize.path(@upload_files[file_type_sym].path).size.join("x")
                @upload_files[file_type_sym].small_dimensions = @upload_files[file_type_sym].resize_from_s(Fs2File::IMAGE_JOB_SEEKER_PLACEHOLDER_SIZES[:small])
                @upload_files[file_type_sym].medium_dimensions = @upload_files[file_type_sym].resize_from_s(Fs2File::IMAGE_JOB_SEEKER_PLACEHOLDER_SIZES[:medium])
                @upload_files[file_type_sym].large_dimensions = @upload_files[file_type_sym].resize_from_s(Fs2File::IMAGE_JOB_SEEKER_PLACEHOLDER_SIZES[:large])
              end
            end
            
            if !@upload_files[file_type_sym].valid?
              is_file_uploaded = false
              next
            else
              # Save the new file information
              @upload_files[file_type_sym].save(false)
            end
          end
          
        end
    
      rescue => e
        
        # Delete the files
        if @upload_files
          @upload_files.each do |file_key, file_obj|
            file_obj.delete
          end
        end
        
        is_file_uploaded = false
      end
      
      if !is_file_uploaded
        flash[:error] += ', Upload failed. Please try again.' if flash[:error]
        flash[:error] = 'Upload failed. Please try again.' if !flash[:error] 
      end
      
      return is_file_uploaded
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

  def save_fs_profile(data = {}, flags = {})
    begin
      
      # Create a new skills_profile object
      @skills_profile = Fs2SkillsProfile.new({
        :profile_type => flags[:profile_type],
        :entity_type => flags[:entity_type],
        :entity_id => flags[:entity_id]
      })
      @skills_profile.label = data[:label] if data[:label] 

      raise 'ERROR' if !@skills_profile.valid?
      
      @skills_profile.save(false)
      
      # -----------------------
      # 2. Set the 'skills_profile' id in the entire 5skills data structure
      # -----------------------
      # TODO: Improve 'INSERT' statements using 'insert select' -> minimize DB calls
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
  
  def delete_job_seeker_fs_profile(job_seeker_id)
    job_fs_profiles = Fs2SkillsProfile.find(:all, :conditions => ["profile_type = ? AND entity_type = ? AND entity_id = ?", FS_PROFILE_TYPES[:user_profile], ENTITY_TYPES[:job_seeker], job_seeker_id])
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
  end
  
  def delete_fs_profile_by_fs_profile_id(fs_profile_id)
    return if !fs_profile_id
    
    # js_sprofiles_match = Fs2SkillsProfilesMatch.find_by_js_skills_profile_id(@fs_profile_id)
    # Fs2SkillsProfilesMatch.destroy_all(["js_skills_profile_id = ?", @fs_profile_id]) if js_sprofiles_match
    # Fs2SkillsProfile.destroy(@fs_profile_id)
    
    Fs2SkillsProfilesMatch.connection.execute("delete from fs2_skills_profiles_matches where js_skills_profile_id = " + fs_profile_id.to_s)
    Fs2SkillsProfile.connection.execute("delete from fs2_skills_profiles where id = " + fs_profile_id.to_s)
    Fs2Skill.connection.execute("delete from fs2_skills where skills_profile_id = " + fs_profile_id.to_s)
    Fs2SkillDetail.connection.execute("delete from fs2_skill_details where skills_profile_id = " + fs_profile_id.to_s)
    Fs2AdditionalRequirement.connection.execute("delete from fs2_additional_requirements where skills_profile_id = " + fs_profile_id.to_s)
      
  end
  
  def attach_fs_profile_to_entity(fs_profile_id, entity_id, entity_type_id, duplicate = false)
    
    fs_profile = Fs2SkillsProfile.find_by_id(fs_profile_id)
    return nil if !fs_profile
    
    if duplicate
      
    else
      fs_profile.update_attributes({:entity_id => entity_id, :entity_type => entity_type_id})
    end
  end
  
  # 
  # If 'job_seeker_id' is null, assume this skills profile will be assigned to a job
  #
  def save_skills_profile(flags = {})
    
    profile_type = entity_id = entity_type = nil
    
    if flags[:job_seeker_id]
      entity_id = flags[:job_seeker_id]
      entity_type = ENTITY_TYPES[:job_seeker]
      profile_type = FS_PROFILE_TYPES[:user_profile]
       
    elsif flags[:job_id]
      entity_id = flags[:job_id]
      entity_type = ENTITY_TYPES[:job]
      profile_type = FS_PROFILE_TYPES[:user_profile]
      
    end
    
    current_skills_profile = Fs2SkillsProfile.find_by_entity_id(entity_id)
    delete_fs_profile_by_fs_profile_id(current_skills_profile.id) if current_skills_profile
    
    begin
      
      # Create a new skills_profile object
      @skills_profile = Fs2SkillsProfile.new({
        :entity_id => entity_id,
        :entity_type => entity_type,
        :profile_type => profile_type
      })
      raise 'ERROR' if !@skills_profile.valid?
      
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
  
  def download_file
    @file = Fs2File.find_by_id(params[:file_id])
    
    send_file @file.path, :type => @file.mime_type, :disposition => 'attachment' if @file
  end
  
  def show_file
    @file = Fs2File.find_by_id(params[:file_id])
    
    send_file @file.path, :type => @file.mime_type, :disposition => 'inline' if @file
  end
  
  
  
  # ----------------------------------------
  #   SENDING 'CV' TO EMPLOYER / RECRUITER
  # ----------------------------------------
  
  
  def email__job_seeker__application_sent(job_seeker_id, job_id, email_type)
    
    # --- 1. FETCH - JOB STUFF
    
    
    job_map = fetch_job_profile(job_id, nil)
    
    js_hash = {}
    js_hash[:job] = {:id => job_map[:job_obj].id, :title => job_map[:job_obj].title}
    js_hash[:job][:map] = job_map
    js_hash[:job][:skills_profile] = job_map[:fs_profiles][job_map[:fs_profiles][:info][:active_fs_profile_id]]
  
  
    # --- 2. FETCH - JOB SEEKER STUFF
    
    
    job_seeker_map = fetch_job_seeker_profile(job_seeker_id, job_id)
    
    js_hash[:job_seeker] = {:id => job_seeker_map[:job_seeker_obj].id, :full_name => job_seeker_map[:job_seeker_obj].full_name}
    js_hash[:job_seeker][:map] = job_seeker_map
    js_hash[:job_seeker][:skills_profile] = job_seeker_map[:fs_profiles][job_seeker_map[:fs_profiles][:info][:active_fs_profile_id]]
    
    
    transaction_h = {:email_type => email_type}  
    transaction_h[:exchange_type] = Fs2Mailer::EMAIL_EXCHANGE_TYPES[:system_to_job_seeker] 
    metadata_params_h = {
      :recipients => [{
        :id => job_seeker_map[:user_obj].id, 
        :email => job_seeker_map[:user_obj].email,
        :name => job_seeker_map[:job_seeker_obj].full_name}]}
        
    
    # ----------------------------------------------
    # Error handling for test users without 'user' objects in the database
    # ----------------------------------------------
    if job_seeker_map[:job_seeker_obj].nil?
      flash[:error_hold] = "Oops! you tried to interact with a 'test' system user, try a different one!"
      return false
    end
    
    # Profile Photo
    if job_seeker_map[:files][:profile_photo]
      js_hash[:job_seeker][:profile_photo] = {
        :file_id => job_seeker_map[:files][:profile_photo].id,
        :small_dimensions => job_seeker_map[:files][:profile_photo].small_dimensions,
        :medium_dimensions => job_seeker_map[:files][:profile_photo].medium_dimensions}
    end
    
    # CV
    if job_seeker_map[:files][:cv]
      js_hash[:job_seeker][:cv] = {
        :file_id => job_seeker_map[:files][:cv].id,
        :file_name => job_seeker_map[:files][:cv].name,
        :file_mime_type => job_seeker_map[:files][:cv].mime_type,
        :file_path => job_seeker_map[:files][:cv].path}
        
    end

    # --->   Send 'job_seeker' details   <---
    # - - - - - - - - - - - - - - - - - - - - 
    return send_message(metadata_params_h, js_hash, transaction_h)    
  end
  
  
  #
  # Default method
  #
  def email_cv_to_recruiter(job_id)
    email__recruiter__application_with_cv(session[:person].id, job_id, Fs2Mailer::EMAIL_TYPES[:cv_sent_for_job])
  end
  
  
  #
  # This methods accepts 3 parameters:
  #  - 'job_seeker_id'
  #  - 'job_id'
  #  - 'email_type' - indicating the 'template' to use for this email
  #
  # The following must be available prior to using this method:
  #  - 'Job' -> has either an 'Agency' or a 'Company' associated with it, otherwise, an Error will be thrown
  #  - 'Job seeker' -> Has to be an existing one in the database, otherwise, an error will be thrown
  #
  # The method does the following:
  #  - 'Fetch' the job details
  #  - 'Fetch' the job seeker details
  #
  def email__recruiter__application_with_cv(job_seeker_id, job_id, email_type)
    
    
    # --- 1. FETCH - JOB STUFF
    
    
    job_map = fetch_job_profile(job_id, nil)
    
    js_hash = {}
    js_hash[:job] = {:id => job_map[:job_obj].id, :title => job_map[:job_obj].title}
    js_hash[:job][:map] = job_map
    js_hash[:job][:skills_profile] = job_map[:fs_profiles][job_map[:fs_profiles][:info][:active_fs_profile_id]]
    
    transaction_h = {:email_type => email_type}

    # --->   Recruitment agents   <---
    # - - - - - - - - - - - - - - - - - - 
    if job_map[:agency_contact_obj] && 
        job_map[:agency_contact_user_obj] && job_map[:agency_contact_user_obj].id && job_map[:agency_contact_user_obj].email
      
      transaction_h[:exchange_type] = Fs2Mailer::EMAIL_EXCHANGE_TYPES[:system_to_recruitment_agent] 
      metadata_params_h = {
        :recipients => [{
          :id => job_map[:agency_contact_user_obj].id, 
          :email => job_map[:agency_contact_user_obj].email,
          :name => job_map[:agency_contact_obj].full_name}]}
      
    # --->   Hiring managers   <---
    # - - - - - - - - - - - - - - - - - - 
    elsif job_map[:company_contact_obj] && 
        job_map[:company_contact_user_obj] && job_map[:company_contact_user_obj].id && job_map[:company_contact_user_obj].email

      transaction_h[:exchange_type] = Fs2Mailer::EMAIL_EXCHANGE_TYPES[:system_to_hiring_manager] 
      metadata_params_h = {
        :recipients => [{
          :id => job_map[:company_contact_user_obj].id, 
          :email => job_map[:company_contact_user_obj].email, 
          :name => job_map[:company_contact_obj].full_name}]}
    else
      flash[:error_hold] = "No agent or hiring manager set for this job, can't send email"
      return false  
    end
  
  
    # --- 2. FETCH - JOB SEEKER STUFF
    
    
    job_seeker_map = fetch_job_seeker_profile(job_seeker_id, job_id)
    
    js_hash[:job_seeker] = {:id => job_seeker_map[:job_seeker_obj].id, :full_name => job_seeker_map[:job_seeker_obj].full_name}
    js_hash[:job_seeker][:map] = job_seeker_map
    js_hash[:job_seeker][:skills_profile] = job_seeker_map[:fs_profiles][job_seeker_map[:fs_profiles][:info][:active_fs_profile_id]]
    
    # ----------------------------------------------
    # Error handling for test users without 'user' objects in the database
    # ----------------------------------------------
    if job_seeker_map[:job_seeker_obj].nil?
      flash[:error_hold] = "Oops! you tried to interact with a 'test' system user, try a different one!"
      return false
    end
    
    # Profile Photo
    if job_seeker_map[:files][:profile_photo]
      js_hash[:job_seeker][:profile_photo] = {
        :file_id => job_seeker_map[:files][:profile_photo].id,
        :small_dimensions => job_seeker_map[:files][:profile_photo].small_dimensions,
        :medium_dimensions => job_seeker_map[:files][:profile_photo].medium_dimensions}
    end
    
    # CV
    if job_seeker_map[:files][:cv]
      js_hash[:job_seeker][:cv] = {
        :file_id => job_seeker_map[:files][:cv].id,
        :file_name => job_seeker_map[:files][:cv].name,
        :file_mime_type => job_seeker_map[:files][:cv].mime_type,
        :file_path => job_seeker_map[:files][:cv].path}
        
    end

    # --->   Send 'job_seeker' details   <---
    # - - - - - - - - - - - - - - - - - - - - 
    return send_message(metadata_params_h, js_hash, transaction_h)
    
  end
  
  def update_cv_transactions_log
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
  
end
