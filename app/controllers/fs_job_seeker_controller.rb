# require 'image_size'
# require 'mechanize'
# require 'yaml'
require 'fastercsv'
require 'iconv'

class FsJobSeekerController < FsLoginController
  
  ANONYMOUS_COMPANY_TYPES = {:unknown => 0, :private => 1, :non_profit => 2, :public => 3, :public => 4}
  ANONYMOUS_COMPANY_SIZES = {:unknown => 0, :start_up => 1, :small => 2, :medium => 3, :large => 4, :very_large => 5}
  ANONYMOUS_COMPANY_MARKETS = {:unknown => 0, :local => 1, :regional => 2, :state => 3, :national => 4, :multinational => 5}
  
  
  before_filter :convert_job_ref_key_to_job_id, 
    :only => [
      :view_job_post,
      :ajax_apply_to_job_post,
      :ajax_save_job_seeker_fs_profile,
      :ajax_i_want_more_jobs,
      :fajax_send_job_post_application,
    ]
  
  
  # -- Ensure the 'job_id' retrieved from the client is converted to the 'real' job_id for easy processing
  #
  def convert_job_ref_key_to_job_id
     job_publishing_post_entity = Fs2JobPublishingPost.find_by_ref_key(params[:job_ref_key])
     if job_publishing_post_entity
       
       params[:job_id] = job_publishing_post_entity.job_id
       params[:job_publishing_post_id] = job_publishing_post_entity.id
     end
  end
  
  
  def linkedin_catchup_all_connections
    users = Fs2User.find(
      :all,
      :joins => ["LEFT JOIN fs2_user_connectors on fs2_user_connectors.user_id = fs2_users.id", 
        "LEFT JOIN `fs2_user_network_connections` ON fs2_user_network_connections.user_connector_id = fs2_user_connectors.id"],
      :select => "fs2_user_connectors.*, fs2_user_network_connections.friend_linkedin_id", 
      :conditions => ["fs2_user_connectors.user_id = ?", 137.to_s])
    
    i = 1
    users.each do |single_user|
      puts "--- " + single_user.linkedin_first_name + " " + single_user.linkedin_first_name + " : " + single_user.friend_linkedin_id
      
      if single_user.friend_linkedin_id != "private"
        my_profile = do_linkedin_by_person_id(single_user.friend_linkedin_id, {:access_token => single_user.linkedin_access_token, :access_secret => single_user.linkedin_access_secret})
        
        if my_profile && my_profile['skills'] && my_profile['skills']['values'] 
          my_profile['skills']['values'].each do |skill_obj|
            puts " --- Skill: " + skill_obj['skill']['name'].to_s
          end
        end
      end
      
      break if i == 10
      
      i += 1
    end
  end
  
  
  
  
  def scraper_catchup
    users_table = FasterCSV.read("db/temp_data/_USERS.csv")
    user_skills_table = FasterCSV.read("db/temp_data/_Skills_quotes.csv") # 'skills_quotes' replaces double quotes with single quotes    
    user_positions_table = FasterCSV.read("db/temp_data/_Positions_quotes.csv") # 'positions quotes' - removed double quotes and a comma that appear in the same cell. The cell contains Hebrew letters    
    user_educations_table = FasterCSV.read("db/temp_data/_Educations_quotes.csv") # 'positions quotes' - removed double quotes and a comma that appear in the same cell. The cell contains Hebrew letters
    all_companies_table = FasterCSV.read("db/temp_data/Companies.csv")
    # all_educations_table = FasterCSV.read("db/temp_data/Educations_quotes.csv") # 'positions quotes' - removed double quotes from cells' contents. The cells contains Hebrew letters
    # all_skills_table = FasterCSV.read("db/temp_data/Skills_quotes.csv")
    
    lin_profiles = Hash.new
    
    # --- Profiles
    
    i_row = 1
    while users_table[i_row] && users_table[i_row][0] && !users_table[i_row][0].blank? do
      user_id = users_table[i_row][0]
      lin_profiles[user_id] = Hash.new
      
      
      # --- User information
    
      lin_profiles[user_id]['firstName'] = users_table[i_row][1]
      lin_profiles[user_id]['lastName'] = users_table[i_row][2]
      lin_profiles[user_id]['publicProfileUrl'] = users_table[i_row][3]
      lin_profiles[user_id]['id'] = users_table[i_row][6]
      lin_profiles[user_id]['industry'] = users_table[i_row][5]
      lin_profiles[user_id]['location'] = {:name => users_table[i_row][4]}
      
      
      # --- Positions
      
      lin_profiles[user_id]['positions'] = {'_total' => -1, 'values' => Array.new}
      
      i_col = 2 # start from first position
      i_position = 0
      while user_positions_table[i_row] && user_positions_table[i_row][i_col] && !user_positions_table[i_row][i_col].blank? do
        # puts " - #{i_row} - " + user_positions_table[i_row][i_col]
        
        lin_profiles[user_id]['positions']['values'][i_position] = Hash.new
        
        # --- title
        if user_positions_table[i_row][i_col + 1] && !user_positions_table[i_row][i_col + 1].blank?
          lin_profiles[user_id]['positions']['values'][i_position]['title'] = user_positions_table[i_row][i_col + 1]
        end
        
        # --- company
        if user_positions_table[i_row][i_col + 2] && !user_positions_table[i_row][i_col + 2].blank?
          # + id
          lin_profiles[user_id]['positions']['values'][i_position]['company'] = {'id' => user_positions_table[i_row][i_col + 2]}
          company_index = nil
          
          # + all other details
          all_companies_table.each_index do |company_row|
            if all_companies_table[company_row][0] == user_positions_table[i_row][i_col + 2]
              company_index = company_row
              break
            end
          end
          if company_index
            lin_profiles[user_id]['positions']['values'][i_position]['company']['name'] = all_companies_table[company_index][1]
            lin_profiles[user_id]['positions']['values'][i_position]['company']['industry'] = all_companies_table[company_index][9]
            lin_profiles[user_id]['positions']['values'][i_position]['company']['size'] = all_companies_table[company_index][10]
          end 
        end
        
        # --- startDate
        if user_positions_table[i_row][i_col + 3] && !user_positions_table[i_row][i_col + 3].blank?
          date_split = user_positions_table[i_row][i_col + 3].split("/")
          if date_split.length > 1 # full_date, 0 - month, 1 - day, 2 - year
            lin_profiles[user_id]['positions']['values'][i_position]['startDate'] = {'year' => date_split[2], 'month' => date_split[0]}
          elsif date_split.length == 1 # only year
            lin_profiles[user_id]['positions']['values'][i_position]['startDate'] = {'year' => date_split[0]}
          end
        end
        
        # --- endDate
        if user_positions_table[i_row][i_col + 4] && !user_positions_table[i_row][i_col + 4].blank?
          date_split = user_positions_table[i_row][i_col + 4].split("/")
          if date_split.length > 1 # full_date, 0 - month, 1 - day, 2 - year
            lin_profiles[user_id]['positions']['values'][i_position]['endDate'] = {'year' => date_split[2], 'month' => date_split[0]}
          elsif date_split.length == 1 # only year
            lin_profiles[user_id]['positions']['values'][i_position]['endDate'] = {'year' => date_split[0]}
          end
        end
        
        # --- isCurrent
        if user_positions_table[i_row][i_col + 4] && !user_positions_table[i_row][i_col + 4].blank?
          lin_profiles[user_id]['positions']['values'][i_position]['isCurrent'] = true
        end
        
        i_col += 6
        i_position += 1
      end
      
      # Update the total no. of positions
      lin_profiles[user_id]['positions']['_total'] = i_position
      
      
      # --- Educations
      
      lin_profiles[user_id]['educations'] = {'_total' => -1, 'values' => Array.new}
      
      i_col = 2 # start from first education
      i_education_row = i_row - 1 # education files don't have header at this point
      i_education = 0
      while user_educations_table[i_education_row] && user_educations_table[i_education_row][i_col] && !user_educations_table[i_education_row][i_col].blank? do
        lin_profiles[user_id]['educations']['values'][i_education] = Hash.new
        
        # --- schoolName
        if user_educations_table[i_education_row][i_col + 1] && !user_educations_table[i_education_row][i_col + 1].blank?
          lin_profiles[user_id]['educations']['values'][i_education]['schoolName'] = user_educations_table[i_education_row][i_col + 1]
        end
        
        # --- degree
        if user_educations_table[i_education_row][i_col + 2] && !user_educations_table[i_education_row][i_col + 2].blank?
          lin_profiles[user_id]['educations']['values'][i_education]['degree'] = user_educations_table[i_education_row][i_col + 2]
        end
        
        # --- fieldOfStudy
        if user_educations_table[i_education_row][i_col + 3] && !user_educations_table[i_education_row][i_col + 3].blank?
          lin_profiles[user_id]['educations']['values'][i_education]['fieldOfStudy'] = user_educations_table[i_education_row][i_col + 3]
        end
        
        i_col += 4
        i_education += 1
      end
      
      # Update the total no. of educations
      lin_profiles[user_id]['educations']['_total'] = i_education
      
      
      # --- Skills
      
      lin_profiles[user_id]['skills'] = {'_total' => -1, 'values' => Array.new}
      
      i_col = 2 # start from first education
      i_skill = 0
      while user_skills_table[i_row] && user_skills_table[i_row][i_col] && !user_skills_table[i_row][i_col].blank? do
        lin_profiles[user_id]['skills']['values'][i_skill] = Hash.new
        
        # --- name
        if user_skills_table[i_row][i_col] && !user_skills_table[i_row][i_col].blank?
          lin_profiles[user_id]['skills']['values'][i_skill]['skill'] = {'name' => user_skills_table[i_row][i_col]}
        end
        
        i_col += 4
        i_skill += 1
      end
      
      # Update the total no. of educations
      lin_profiles[user_id]['skills']['_total'] = i_skill
      
      
      i_row += 1
    end
    
    
    # --- Initialize all scraped linkedin users
    
    scraper_init_linkedin_users(lin_profiles)
    
    
    render 'linkedin_catchup.html', :layout => '__seeker_profile_layout'
  end
  
  def ajax_i_want_more_jobs
    is_error = false
    
    begin
        
      # --- X. Update the funnel status
      #   Currently, assumption is that the logged-in user is a 'job_seeker' and not a 'recruiter'
    
      funnel = Fs2UserMarketingFunnel.find_by_user_id(id("user__job_seeker"))
      funnel.update_attributes({:state_id => 3}) if funnel.state_id < 3
      
      @arr = {
          :status => "200",
          :action => "applied_successfully__more_jobs",
          :message => nil
        }
    
    rescue Exception => exc
      
      is_error = true
      
    end
    
    if is_error
      @arr = {
          :status => "50",
          :action => "applied_successfully__more_jobs",
          :message => 'Errors were found in the fields below, please check the messages next to each field'
        }
    end
        
    respond_to do |format|
      
      format.json {  
        render :json => @arr.to_json, :callback => params[:callback] 
      }
      
    end    
    
  end
  
  def scraper_init_linkedin_users(lin_profiles)
    
    # --- 1. Run 'linkedin_catchup'
    #
    # This will run through all connectors, retrieve their connections and create the appropriate DB fields for them
    
    # linkedin_catchup
    
    
    # --- 2. Iterate through all scraped profiles
    
    tt = 1
    lin_profiles.each do |remote_user_id, lin_profile|
      
      tt += 1
      # break if tt == 100
      
      user = nil
      user_connector = nil
      job_seeker = nil
      
      # 1. Try and locate an existing 'connector'
      
      if lin_profile['id']
        user_connector = Fs2UserConnector.find_by_linkedin_id(lin_profile['id'])
      elsif lin_profile['emailAddress']
        user_connector = Fs2UserConnector.find_by_linkedin_email(lin_profile['emailAddress'])
      elsif lin_profile['publicProfileUrl']
        user_connector = Fs2UserConnector.find_by_linkedin_email(lin_profile['publicProfileUrl'])
      end
      
      # 2. Retrieve the 'user' object
      
      # + Connector found
      if user_connector && user_connector.user_id
        user = Fs2User.find_by_id(user_connector.user_id)
        job_seeker = Fs2JobSeeker.find_by_user_id(user.id) if user
      end 
      
      
      # --- CREATE objects ---
      
      # + 'User' not found
      if user.nil?
        # Create USER
        user = Fs2User.new({
          :user_type_id => Fs2User::USER_TYPES[:job_seeker],
          :status_id => Fs2User::USER_STATUSES[:scraped],
          :referral_id => Fs2User::USER_REFERRALS[:added_through_friend]
        })
        user.email = lin_profile['emailAddress'] if lin_profile['emailAddress']
        user.save(false)
      end
      
      # + 'Job seeker' not found
      if job_seeker.nil?
        # Create JOB SEEKER
        full_name = ""
        full_name += lin_profile['firstName'] if lin_profile['firstName']
        if lin_profile['lastName']
          full_name += " " if !full_name.blank?
          full_name += lin_profile['lastName']  
        end
        
        job_seeker = Fs2JobSeeker.new({:full_name => encode_utf(full_name)})
        job_seeker.user_id = user.id
        job_seeker.save(false)
      end
      
      # + 'Connector' not found
      if user_connector.nil?
        # Create USER CONNECTOR
        user_connector = Fs2UserConnector.new({:status_id => -1})
        user_connector.user_id = user.id if user
        user_connector.linkedin_id = lin_profile['id'] if lin_profile['id']
        user_connector.linkedin_email = lin_profile['emailAddress'] if lin_profile['emailAddress']
        user_connector.linkedin_first_name = encode_utf(lin_profile['firstName']) if lin_profile['firstName']
        user_connector.linkedin_last_name = encode_utf(lin_profile['lastName']) if lin_profile['lastName']
        user_connector.linkedin_public_profile_url = lin_profile['publicProfileUrl'] if lin_profile['publicProfileUrl']
        user_connector.save(false)  
      end
      
      
      # --- PRINT ---
     
      if lin_profile['skills'] && lin_profile['skills']['values']
        skill_s = "[" + lin_profile['id'] + "] "
        lin_profile['skills']['values'].each do |skill|
          skill_s += skill['skill']['name'] + ", "
        end
        puts skill_s
      end
      
      save_complete_profile(user_connector, lin_profile)
      
    end
     
  end
  
  #
  # Assumptions for this method:
  #
  # 1. user_id exists in the 'user_connectors' table, i.e.
  #  - Fs2User table exists
  #  - Fs2JobSeeker table exists
  #
  def linkedin_catchup
    
    # 2. Grab more details from LinkedIn
    user_connectors = Fs2UserConnector.find(:all)
    # user_connectors = Fs2UserConnector.find(:all, :conditions => ["user_id = ?", 134.to_s]) # TOMER SAGI = 32
    
    if user_connectors
      user_connectors.each do |user_connector|
        linkedin_user_profile = do_linkedin(4, nil, {:access_token => user_connector.linkedin_access_token, :access_secret => user_connector.linkedin_access_secret})
        linkedin_user_profile = do_linkedin(1, nil, {:access_token => user_connector.linkedin_access_token, :access_secret => user_connector.linkedin_access_secret}) if linkedin_user_profile.nil?
        
        if linkedin_user_profile.nil?
          puts " -------- SKIPPED user profile, probably no permissions: " + user_connector.linkedin_first_name.to_s + " " + user_connector.linkedin_last_name.to_s 
          next
        end
        
        fs_profile = save_complete_profile(user_connector, linkedin_user_profile)
        
      end
    else
      @error = "Linkedin 'profile' error occured! Check your logs."
    end
    
    render 'linkedin_catchup.html', :layout => '__seeker_profile_layout'
    
  end  
  
  #
  # This method saves a complete LINKEDIN profile
  #
  # Recieves the following objects:
  #
  #  'user_connector': The 'Fs2UserConnector' object
  #     * Assuming the connector has a 'user_id' in the DB
  #  'linkedin_user_profile': The 'linkedin_api' object
  #
  # What it does:
  #
  #  Checks if the connector has an existing 'user_id' in the DB
  #  Checks if the connector has a 'Fs2JobSeeker' object in the db, otherwise, creates a new one 
  # 
  def save_complete_profile(user_connector, linkedin_user_profile)    
    job_seeker = Fs2JobSeeker.find_by_user_id(user_connector.user_id)
    
    if job_seeker.nil?
      full_name = ""
      full_name += linkedin_user_profile['firstName'] if linkedin_user_profile['firstName']
      if linkedin_user_profile['lastName']
        full_name += " " if !full_name.blank?
        full_name += linkedin_user_profile['lastName']  
      end
        
      job_seeker = Fs2JobSeeker.new({
        :full_name => full_name})
      job_seeker.user_id = user_connector.user_id
      job_seeker.save(false)
    end
    
    
    # --------- SAVE SKILLs ---------
    
    save_linkedin_skills(job_seeker.id, linkedin_user_profile)
    
    
    # --------- CV ---------
      
    # 1. Check if there is an existing CV in the system
    cv = Fs2Cv.find_or_create_by_job_seeker_id(job_seeker.id)
    cv.save(false) if cv.id.nil?
    
    fs_profile = {
      :positions => anonymize_positions(linkedin_user_profile),
      :linkedin_obj => linkedin_user_profile}
    
    
    # --------- SPECIFIC CATCH-UPS ---------
    
    # Check if specific fields need to go through the 'catch-up', if so, skip the standard catching up
    if params[:flag_position]
      
      positions = Fs2CvPosition.find(
        :all,
        :joins => "LEFT JOIN `fs2_anonymous_companies` ON fs2_anonymous_companies.id = fs2_cv_positions.anonymous_company_id" ,
        :select => "fs2_cv_positions.*, fs2_anonymous_companies.linkedin_company_name", 
        :conditions => ["fs2_cv_positions.cv_id = ?", cv.id])
      
      if positions 
        positions.each do |db_position|
          
          found = false
          
          fs_profile[:linkedin_obj]['positions']['values'].each do |position|
            
            if db_position.start_month == position['startDate']['month'] && 
                db_position.start_year == position['startDate']['year'] && 
                db_position.linkedin_company_name == position['company']['name']
              puts "---- " + position['id'].to_s + "|" + position['title'] + " / " + db_position.end_month.to_s + "|" + db_position.start_month.to_s
              
              db_position.update_attributes({:title => position['title'], :linkedin_position_id => position['id'].to_s})
              
              found = true
              break
            end
              
          end
          
          puts " !!!!! Not found" if !found
          
        end
      end
      
      return
    end
    
    
    # --------- POSITIONS ---------
    
    first_position = Fs2CvPosition.find(:first, :conditions => ["cv_id = ?", cv.id.to_s])
    
    if first_position.nil?
      
      fs_profile[:positions][:all].each do |position|  
      
        
        # --------- INDUSTRIES and COMPANIES ---------
        
        if position[:linkedin_position]['company']
        
          # 3. Industry - check if exists first
          industry = Fs2Industry.find_or_create_by_name(position[:linkedin_position]['company']['industry']) if position[:linkedin_position]['company']['industry']
          industry.save(false) if industry && industry.id.nil?
        
          # 4. Create the company
          db_company = Fs2AnonymousCompany.find_or_create_by_linkedin_company_name(position[:linkedin_position]['company']['name']) if position[:linkedin_position]['company']['name']
          
          if db_company.id.nil?
            
            db_company.linkedin_company_id = position[:linkedin_position]['company']['id'].to_i if position[:linkedin_position]['company']['id']
            db_company.linkedin_company_name = position[:linkedin_position]['company']['name'] if position[:linkedin_position]['company']['name']
            
            # --- TYPE
            db_company.type_id = ANONYMOUS_COMPANY_TYPES[:private] if position[:linkedin_position]['company']['type'] == "Privately Held"
            db_company.type_id = ANONYMOUS_COMPANY_TYPES[:unknown] if position[:linkedin_position]['company']['type'] != "Privately Held"
            
            # --- SIZE
            db_company.size_id = position[:company_size_type_id] if position[:company_size_type_id]
            
            # --- MARKET
            db_company.market_id = ANONYMOUS_COMPANY_MARKETS[:unknown]
            
            # --- INDUSTRY
            db_company.industry_id = industry.id if industry && industry.id
            
            # --- ADDRESS
            # db_company.address_region = ?
            # db_company.address_city = ?
            # db_company.address_country = ?
            
            db_company.save(false)
            
          end
        
        end
        
        
        # 3. If no positions exist in the DB, add them into the system
        db_position = Fs2CvPosition.new
        db_position.cv_id = cv.id
        db_position.domain = "Unknown"
        db_position.anonymous_company_id = db_company.id if db_company 
        db_position.title = encode_utf(position[:linkedin_position]['title'])
        db_position.linkedin_position_id = position[:linkedin_position]['id'].to_s
        
        if position[:linkedin_position]['startDate']
          db_position.start_month = position[:linkedin_position]['startDate']['month'] if position[:linkedin_position]['startDate']['month']
          db_position.start_year = position[:linkedin_position]['startDate']['year'] if position[:linkedin_position]['startDate']['year']
        end
        
        if position[:linkedin_position]['endDate']
          db_position.end_month = position[:linkedin_position]['endDate']['month'] if position[:linkedin_position]['endDate']['month']
          db_position.end_year = position[:linkedin_position]['endDate']['year'] if position[:linkedin_position]['endDate']['year']
        else
          db_position.is_current = true
        end
        
        db_position.save(false)
        
      end
      
    end
    
    
    # --------- EDUCATIONS ---------
    
    first_education = Fs2CvEducation.find(:first, :conditions => ["cv_id = ?", cv.id.to_s])
    
    if first_education.nil? && linkedin_user_profile['educations'] && linkedin_user_profile['educations']['values']
         
      linkedin_user_profile['educations']['values'].each do |education|
        
        # Education institute
        education_institute = Fs2EducationInstitute.find_or_create_by_linkedin_education_institute_name(encode_utf(education['schoolName'])) if education['schoolName']
        education_institute.save(false) if education_institute.id.nil?
        
        db_education = Fs2CvEducation.new
        db_education.cv_id = cv.id
        db_education.degree = education['degree'] if education['degree'] 
        db_education.field = education['fieldOfStudy'] if education['fieldOfStudy']
        db_education.anonymous_education_institute_id = education_institute.id
        
        db_education.save(false)
        
      end
      
    end
    
    # ----- Complete missing parts -----
    
    first_connection = Fs2UserNetworkConnection.find(:first, :conditions => ["user_connector_id = ?", user_connector.id.to_s])
    
    if first_connection.nil? && linkedin_user_profile['connections'] && linkedin_user_profile['connections']['values'] 
      insert_sql = "insert into fs2_user_network_connections (user_connector_id, friend_linkedin_id) values"
      x = 0
        
      linkedin_user_profile['connections']['values'].each do |connection|
        insert_sql += "," if x > 0
        insert_sql += " (" + user_connector.id.to_s + ", '" + connection['id'] + "')"
        
        x += 1
      end
      
      Fs2UserNetworkConnection.connection.execute(insert_sql)
    end
    
    
    # --- Convert the 'new' connections to 'user_connector' objects
    
    linkedin_catchup_connections(user_connector.id.to_s, linkedin_user_profile)
    
    
    return fs_profile
    
  end
  
  
  
  #
  #
  # LINKEDIN - CATCHUP
  # 
  # - CONNECTIONS
  #
  #
  def linkedin_catchup_connections(user_connector_id, linkedin_user_profile)
    
    if linkedin_user_profile['connections'] && linkedin_user_profile['connections']['values']
              
              
      # ---------------------------- INSERT ----------------------------
      # --- 1. Find all 'friends' that don't have a 'user_connector' object in the DB
      
      # First, find all the 'unique' linkedin_ids from both fs2_user_connectors and fs2_user_network_connections
      unique_linkedin_ids_sql = "select distinct friends.friend_linkedin_id" + 
        " from fs2_user_network_connections friends" + 
        " where friends.friend_linkedin_id NOT IN (select gg.linkedin_id from fs2_user_connectors gg)" +
        " and friends.friend_linkedin_id != 'private'" +   
        " and friends.user_connector_id = " + user_connector_id
        
      db_unique_linkedin_ids = Fs2UserNetworkConnection.connection.execute(unique_linkedin_ids_sql)
    
      
      # --- 2. Insert 'friends' linkedin_ids' into the 'user_connector' table
      
      if db_unique_linkedin_ids
        
        unique_linkedin_ids = Array.new
        db_unique_linkedin_ids.each { |result| unique_linkedin_ids << result[0] }
        
        if !unique_linkedin_ids.empty?
          
          id_collector = Array.new
          insert_sql = "insert into fs2_user_connectors (linkedin_id, linkedin_first_name, linkedin_last_name, linkedin_public_profile_url, status_id) values"
          x = 0
        
          # Iterate over all connections and populate them in the fs2_user_connectors table
          linkedin_user_profile['connections']['values'].each do |connection|
            
            # fs2_user_connectors
            # --------------------
            #
            # Add 'new inactive' users to the fs2_user_connectors table
            if connection['id'] && connection['id'] != "private" && unique_linkedin_ids.index(connection['id'])
              insert_sql += "," if x > 0
              insert_sql += " ('" + 
                connection['id'] + "', '" + 
                escape_single_quotes(connection['firstName'].to_s) + "', '" + 
                escape_single_quotes(connection['lastName'].to_s) + "', '" + 
                connection['publicProfileUrl'].to_s + "', -1)"
              
              id_collector << connection['id']
              
              x += 1
            end
            
          end
          
          Fs2UserConnector.connection.execute(insert_sql)
          
        end
          
          
        # ---------------------------- UPDATE ----------------------------
        # --- 3. Add the 'friend_connector_id' attribute into the 'friends' table
        
        # connectors = Fs2UserConnector.find(:all, :select => "id, linkedin_id")
        connectors = Fs2UserConnector.find(
          :all,
          :select => "fs2_user_connectors.id, fs2_user_connectors.linkedin_id",
          :joins => "JOIN `fs2_user_network_connections` ON fs2_user_connectors.linkedin_id = fs2_user_network_connections.friend_linkedin_id" , 
          :conditions => "fs2_user_network_connections.friend_connector_id IS NULL")
      
        
        if connectors && !connectors.empty?
          
          id_collector = Array.new
          update_sql = "UPDATE fs2_user_network_connections" + 
            " SET friend_connector_id = CASE friend_linkedin_id"
            
          connectors.each do |connector|
              update_sql += " WHEN '" + connector.linkedin_id.to_s + "' THEN " + connector.id.to_s
              
              id_collector << connector.linkedin_id.to_s
          end
          
          update_sql += " END" + 
            " WHERE friend_linkedin_id in ('" + id_collector.join("','") + "')"
            
          Fs2UserNetworkConnection.connection.execute(update_sql)
          
        end
        
      end
      
    end
    
  end
  
  def view_seeker_profile_by_recruiter
    
    @job_seeker = fetch_job_seeker_profile(params[:seeker_id], nil)
    @fs_profiles = @job_seeker[:fs_profiles]
    set_active_fs_profile
    
    # user_connector = Fs2UserConnector.find_by_id(params[:user_connector_id])
    # fs_profile = save_complete_profile(user_connector, my_profile)
    
    
    # --- get all positions
    positions = 
    
    connectors = Fs2CvPositions.find(
          :all,
          :select => "fs2_cvs.id, fs2_cv_positions.linkedin_id",
          :joins => "JOIN `fs2_user_network_connections` ON fs2_user_connectors.linkedin_id = fs2_user_network_connections.friend_linkedin_id" , 
          :conditions => "fs2_cvs.job_seeker_id = #{params[:seeker_id]}")
    #   --- extract current positions
    
    # --- get all educations
    
    # Prepare attributes for rendering
    @anon_current_positions = fs_profile[:positions][:current]
    @anon_positions = fs_profile[:positions][:all]
    @my_profile = my_profile
    
    render 'MVP_view_seeker_profile.html', :layout => '__seeker_profile_layout'
  end  
  
  def seeker_home
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
        
    render 'MVP2_seeker_home.html', :layout => '__seeker_home_layout'
  end

  def view_seeker_profile
    
    if params[:test]
      session[:access_token] = "548e9973-d552-4065-8866-f9aa0a6e1593"
      session[:access_secret] = "34f6e793-99e6-4fb0-92c8-12255ef1c7f0"
    end
    
    my_profile = do_linkedin(4) # 4 == including connections
    my_profile = do_linkedin(1) if my_profile.nil? || my_profile['status'] == 500 # 1 == no connections
    
    if my_profile.nil? || session[:user_connector_id].nil?
      do_linkedin_login
      return
    end
    
    user_connector = Fs2UserConnector.find_by_id(session[:user_connector_id])
    fs_profile = save_complete_profile(user_connector, my_profile)
    
    # Prepare attributes for rendering
    @anon_current_positions = fs_profile[:positions][:current]
    @anon_positions = fs_profile[:positions][:all]
    @my_profile = my_profile
    
    render 'MVP_view_seeker_profile.html', :layout => '__seeker_profile_layout'
  end
  
  def save_linkedin_skills(job_seeker_id, my_profile)
    
    skills_profile = Fs2SkillsProfile.find(:first, :conditions => 
      ["profile_type = ? AND entity_type = ? AND entity_id = ?", 
      FS_PROFILE_TYPES[:user_profile], ENTITY_TYPES[:job_seeker], job_seeker_id])
    
    # 1. Flag / insert new skills into the skills table 
    if skills_profile.nil? && my_profile['skills'] && my_profile['skills']['values']
      skills_arr = Array.new
        
      my_profile['skills']['values'].each do |skill_obj|
        skills_arr << skill_obj['skill']['name']
      end
  
      # -- 1 --  Construct a complete ',' separated list of all keywords that makes the current 5skills profile
      @skills = Array.new
      i = 0
  
      # Get the 'KEYWORD IDS' for the keyword names
      @keywords = Fs2SkillKeyword.find_by_sql(
        "SELECT " + 
          "* " + 
        "FROM " + 
          "fs2_keywords " + 
        "WHERE " + 
          "keyword IN ('" + skills_arr.join("','") + "')")
      
      # -- 3 --  Create a Hash that holds the 'EXISTING' keywords and their DB ID
      @existing_keywords_hash = Hash.new
      @keywords_hash = Hash.new
      @keywords.collect { |keyword| @existing_keywords_hash[keyword.keyword] = keyword.id }
      
      # -- 4 --  Complete the '@keywords_hash' hash with all keywords and their DB ID (create new IDs for new keywords)
      Fs2SkillKeyword.transaction do
        begin
          skills_arr.each do |keyword|
            
            if !keyword.blank?
              if @existing_keywords_hash[keyword]
                @current_keyword_id = @existing_keywords_hash[keyword]
              else
                @current_keyword = Fs2Keyword.new({:keyword => keyword})
                @current_keyword.save(false)
                @current_keyword_id = @current_keyword.id 
              end
        
              @keywords_hash[keyword] = @current_keyword_id
              
              @skills[i] = Fs2Skill.new
              @skills[i].priority = i + 1
              @skills[i].keyword_id = @current_keyword_id
              
              i += 1
            end
            
          end                  
        rescue Exception => exc
          puts "*** ERROR: " + exc.message
        end # rescue
      end # transaction
      
      
      
      # *************************
      #   B -> SAVE SKILLS
      # *************************
      
      begin
        
        delete_job_seeker_fs_profile(job_seeker_id)
        
        # Save the FS PROFILE
        skills_profile = save_fs_profile({}, {
            :profile_type => FS_PROFILE_TYPES[:user_profile],
            :entity_type => ENTITY_TYPES[:job_seeker],
            :entity_id => job_seeker_id})
            
        raise 'ERROR' if !skills_profile
      
      rescue Exception => exc
        
        flash[:error] = 'Errors were found in the fields below, please check the messages next to each field'
                  
      end # rescue
      
    end
    
  end
  
  def seek_job_seekers
    
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
    # @sorted_skills = Fs2SkillKeyword.find_by_sql(executable_sql)
    
    render 'MVP_seek_job_seekers.html', :layout => '__seeker_profile_layout' 
  end
  
  def anonymize_positions(linkedin_user_profile)
    positions_h = {:all => Array.new(0), :current => Array.new(0)}
    index = 0
    index_current = 0
    
    return positions_h if linkedin_user_profile.nil? || linkedin_user_profile['positions'].nil?  
    
    linkedin_user_profile['positions']['values'].each do |position|
      
      positions_h[:all][index] = Hash.new
      positions_h[:all][index][:linkedin_position] = position
      positions_h[:all][index][:title] = position['title'].to_s if position['title']
      
      if position['company']
        
        positions_h[:all][index][:company_industry] = position['company']['industry'].to_s if position['company']['industry']
        positions_h[:all][index][:company_industry] = "" if positions_h[:all][index][:company_industry] == "-1" 
        
        # company sizes
        size_s = position['company']['size'].to_s
        
        if size_s == "1-10 employees" || size_s == "11-50 employees"
          positions_h[:all][index][:company_size] = "Small"
          positions_h[:all][index][:company_size_type_id] = ANONYMOUS_COMPANY_SIZES[:small]
        elsif size_s == "51-200 employees" || size_s == "201-500 employees"
          positions_h[:all][index][:company_size] = "Medium"
          positions_h[:all][index][:company_size_type_id] = ANONYMOUS_COMPANY_SIZES[:medium]
        elsif size_s == "501-1000 employees" || size_s == "1001-5000 employees"
          positions_h[:all][index][:company_size] = "Large"
          positions_h[:all][index][:company_size_type_id] = ANONYMOUS_COMPANY_SIZES[:large]
        elsif size_s == "5000-10000 employees" || size_s == "10001+ employees"
          positions_h[:all][index][:company_size] = "Very Large"
          positions_h[:all][index][:company_size_type_id] = ANONYMOUS_COMPANY_SIZES[:very_large]
        end
        
      end 
      
      # position duration
      # positions_h[:all][index][:start_date] = position['startDate']['month'].to_s + " " + position['startDate']['year'].to_s if position['startDate']
      positions_h[:all][index][:start_year] = position['startDate']['year'].to_s if position['startDate']
      
      # calculate
      if position['endDate']
        # positions_h[:all][index][:end_date] = position['endDate']['month'].to_s + " " + position['endDate']['year'].to_s
        positions_h[:all][index][:end_year] = position['endDate']['year'].to_s
        
        if position['endDate']['year'].to_i > position['startDate']['year'].to_i
          positions_h[:all][index][:duration] = (12 - position['startDate']['month'].to_i) + (position['endDate']['month'].to_i) + 
            ((position['endDate']['year'].to_i - position['startDate']['year'].to_i - 1) * 12)
        elsif position['endDate']['year'].to_i == position['startDate']['year'].to_i
          positions_h[:all][index][:duration] = position['endDate']['month'].to_i - position['startDate']['month'].to_i
        end
      else
        # positions_h[:all][index][:end_date] = "Present"
        positions_h[:all][index][:end_year] = "Present"
        positions_h[:current][index_current] = positions_h[:all][index]
        index_current += 1
      end
      
      index += 1
    end
    
    positions_h
  end

  def anonymize_educations
    
  end
  

  def find_job_seekers
    respond_to do |format|
    
      format.html {
        add_skills_profile_binders("search_job_seekers", true)
        
        render 'find_job_seekers.html', :layout => 'five_skills'
      }
      
    end
    
  end
  
  
  def ajax_search_job_seekers
    @fs_results = search_entities_2({:request_fs_profile => @request_fs_profile}, {:entity_type => ENTITY_TYPES[:job_seeker], :include_contact_details => true})
    
    # Save results in session
    # session[:matches] = @js_results_array
    
    respond_to do |format|
      
      format.json {
        @arr = {
            :status => "200",
            :action => "search_job_seekers",
            :results => @fs_results
          }
          
        render :json => @arr.to_json, :callback => params[:callback] 
      }
      
    end    
  end    
  
  def match_with_job
    if !params[:job_seeker_id]
      flash[:error] = 'No "job_seeker_id" provided!'
      render 'view_job_seeker_profile.html', :layout => 'fs_layout_job_seeker_profile'
      return
    end
    
    # --- If USER is not a 'job_seeker' and a JOB exists in session
    # Make sure to grab the 'job' details and perform a match
    if session[:user].user_type_id != Fs2User::USER_TYPES[:job_seeker] && session[:jobs]
      @job_seeker = fetch_job_seeker_profile(params[:job_seeker_id], session[:jobs][:active_job_id])
    else
      @job_seeker = fetch_job_seeker_profile(params[:job_seeker_id], nil)  
    end
    
    @fs_profiles = @job_seeker[:fs_profiles]
    set_active_fs_profile
    
    render 'view_job_seeker_profile.html', :layout => 'fs_layout_job_seeker_profile'
  end
  
  def view_job_matches
    prep_job_seeker_profile(session[:person].id)
    add_ajax_start_up_actions("search_job_matches")
    
    render 'view_job_matches.html', :layout => 'five_skills'
  end



  #
  # -- This method
  #
  # - FINDS
  #   (1) Job Post - Fs2JobPublishingPost (by the job_ref_key)
  #   (2) Job - Fs2Job (by job_post.job_id)
  #   (3) Job Application - (by job_seeker.id)
  #   (4) 5Skills Profile (Active) - Fs2SkillsProfile (from job application)
  # 
  # - CHECKS
  #   (1) If user logged in - is("person__job_seeker") --> Get the Job Application
  #
  # - CREATES
  #   (1) Visitor object - Fs2Visitor
  #   (2) Publishing Post Visitor (mapping between a Visitor and Publishing Post)- Fs2JobPublishingPostVisitor
  #
  def a_recruiter__view_job_post
    
    # !!!!!! Testing - first thing to do, clear the session object
    
    # reset_session
    
    
    # --- LOGIC - 23 Aug, 2014
    #
    # 1. Visitor
    #   - Check if visitor exists based on parameters
    #   - [doesn't exist]
    #       + Create a new visitor
    #       + Create the map of the Visitor to the PublishingPost
    #   - [exists]
    #       + Update the 'updated_at' date of the found Visitor
    #       + Check if the PublishingPost and Visitor pair exists
    #       + [exists] Update the 'updated_at' field
    #       + [doesn't exist] create the mapping
    
    
    # --- X - Get the JOB_POST ID
    
    job_post = Fs2JobPublishingPost.find_by_ref_key(params[:job_ref_key])
    
    
    # --- X - Capture the VISITOR information
    
    req_data = {
      :remote_ip => request.remote_ip,
      :referrer => request.referrer,
      :user_agent => request.env["HTTP_USER_AGENT"]
    }
    
    
    # --- X - Establish if the Visitor is UNIQUE or not
    
    visitor_entry = Fs2Visitor.find(:first, :conditions => ["ip = ? AND agent = ?", req_data[:remote_ip], req_data[:user_agent]])
    
    if visitor_entry
      
      new_visitor = false
      
    else
      
      new_visitor = true
      
      visitor_entry = Fs2Visitor.new({
        :ip => req_data[:remote_ip],
        :referrer => req_data[:referrer],
        :agent => req_data[:user_agent],
        :new_visitor => new_visitor
      })
      visitor_entry.save(false)
      
    end
    
    
    # --- X - Get the JOB object based on the JOB_POST ID
      
    job = fetch_job_profile(
      job_post['job_id'],
      nil,
      {:include_skills_profile => true, :include_publishing_post_info => true})
    
    
    # --- X - Save the MAP between a Visitor and a JOB_POST
    
    if visitor_entry.id
      job_post_visitor_entry = Fs2JobPublishingPostVisitor.new({
        :job_publishing_post_id => job_post['id'],
        :visitor_id => visitor_entry.id
      })
      job_post_visitor_entry.save(false)
    end
    
       
    # --- X - Check if the current VISITOR is a LOGGED IN USER
    
    # If so, retrieve their application and display the appropriate message

    if is("person__job_seeker")
      
      # --- X. Find if the user had applied to job already, if they have, display the appropriate message
      
      application_map = get_job_application(id("person__job_seeker"), params[:job_id])
      
      if application_map
        
        @job_application = application_map[:job_application]
        @active_fs_profile = application_map[:job_seeker_fs_profile]
        
      end
      
    else
      
      
      # --- X. Enable the 'first_time' access
      # add_ajax_start_up_actions("first_time_access")
    
    end
    
    
    # Prepare the 'session_ids'
    @session_ids = URI::escape({
      :visitor_id => visitor_entry.id.to_s,
      :job_id => job[:job_obj].id.to_s,
      :job_status_id => job[:job_obj].status_id.to_s
    }.to_json)
    
    
    render 'a_job_seeker__apply_to_job_post.html', :layout => 'job_seeker/layout_ajs__apply__main'
    
  end


  def view_job_post
    
    # !!!!!! Testing - first thing to do, clear the session object
    
    # reset_session
    
    
    # Perform the 'NEW VISITOR' stuff
    req_data = {
      :remote_ip => request.remote_ip,
      :referrer => request.referrer,
      :user_agent => request.env["HTTP_USER_AGENT"]
    }
    
    
    # --- UNIQUE visitor check

    new_visitor = true    
    if !cookies[:fs_visit]
      # Compare the IP and agent to determine if the visitor is unique
      existing_visitor = Fs2Visitor.find(:first, :conditions => ["ip = ? AND agent = ?", req_data[:remote_ip], req_data[:user_agent]])
      new_visitor = false if existing_visitor
      
      cookies[:fs_visit] = { :value => true, :expires => 1.year.from_now }
    else
      new_visitor = false
    end
    
    
    # --- X. Fetch the 'job_profile' object  
    # job = fetch_job_profile(
      # params[:job_id],
      # nil,
      # {:include_skills_profile => true, :include_publishing_post_info => true})
    
    # -- VISITOR - Add to database
    visitor_entry = Fs2Visitor.new({
      :ip => req_data[:remote_ip],
      :referrer => req_data[:referrer],
      :agent => req_data[:user_agent],
      :new_visitor => new_visitor
    })
    visitor_entry.save(false)
    
    
    # -- JOB PUBLISHING POST VISITOR - Add to database
    if visitor_entry.id
      job_post_visitor_entry = Fs2JobPublishingPostVisitor.new({
        :job_publishing_post_id => params[:job_publishing_post_id],
        :visitor_id => visitor_entry.id
      })
      job_post_visitor_entry.save(false)
    end
    
       
    # --- X. Retrieve the user's 'fs_profile' object if the user exist in session
    
    b = is("person__job_seeker") 
    if is("person__job_seeker")
      
      # --- X. Find if the user had applied to job already, if they have, display the appropriate message
      
      application_map = get_job_application(id("person__job_seeker"), params[:job_id])
      
      if application_map
        
        @job_application = application_map[:job_application]
        @active_fs_profile = application_map[:job_seeker_fs_profile]
      
      else
        
        # --- X. Otherwise, run the match
      
        match_results = _match_job_seeker(id("person__job_seeker"), params[:job_id])
        @match_info = match_results[:job_match]
        
        if @match_info && @match_info[1] && @match_info[1][:match_pct].to_i >= 20
          @match_info_above_threshold = true
        else
          @match_info_above_threshold = true
        end
        
        @active_fs_profile = match_results[:active_fs_profile]
        
      end
      
    else
      
      
      # --- X. Enable the 'first_time' access
      add_ajax_start_up_actions("first_time_access")
    
    
      # --- X. Prepare the 'sorted_skills' list
      # --- * Extract the skills from the source profile - Needs testing
      keyword_in_sql_arr = []
      # job[:fs_profiles][job[:fs_profiles][:info][:active_fs_profile_id]][:skill_ids_matrix].each do |keyword_id|
        # keyword_in_sql_arr << keyword_id[0] # ACTUAL keyword id
      # end
      keyword_in_sql = keyword_in_sql_arr.join(",")
      
      # --- * Add some hard-coded skills to the above list
      keyword_in_sql = keyword_in_sql + ",40315,40313,40304,40246,40337"
 
      # Select specific skills for Wix's 'Leading Client Developer'
      keyword_in_sql = "40337,40315,40313,40304,40246,19119,19135,19346,19348,1230,1232,27122,19129,655,19359,19361,34140,31812,40307,8508,8510"
           
      @include_counters = false
      
      executable_sql =
        "select" + 
          " sk.keyword name, sk.id keyword_id" + 
          # " sk.en_us name, skls.keyword_id, COUNT(skls.skills_profile_id) as cnt_profiles" +  
        " from" + 
          " fs2_keywords sk" +
          # " join fs2_skill_keywords sk on (sk.id = skls.keyword_id)" + 
        " where" + 
          " sk.id > 0" + 
          " AND sk.id in (#{keyword_in_sql})" + 
        " order by name asc"    
      
      # executable_sql =
        # "select" + 
          # " sk.keyword name, skls.keyword_id, COUNT(skls.skills_profile_id) as cnt_profiles" +
          # # " sk.en_us name, skls.keyword_id, COUNT(skls.skills_profile_id) as cnt_profiles" +  
        # " from" + 
          # " fs2_skills skls" + 
          # " join fs2_keywords sk on (sk.id = skls.keyword_id)" +
          # # " join fs2_skill_keywords sk on (sk.id = skls.keyword_id)" + 
          # " join fs2_skills_profiles sp on (sp.id = skls.skills_profile_id)" + 
        # " where" + 
          # " skls.keyword_id > 0" + 
          # " AND sp.entity_type = #{ENTITY_TYPES[:job]}" + 
          # " AND sp.profile_type = #{FS_PROFILE_TYPES[:user_profile]}" +
          # " AND skls.keyword_id in (#{keyword_in_sql})" +
        # " GROUP BY skls.keyword_id" + 
        # " order by cnt_profiles desc, name asc"
        
      @sorted_skills = Fs2Keyword.find_by_sql(executable_sql)
    
    end
    
    # Wix job
    if params[:job_id].to_i == 100 || params[:job_id].to_i == 164
      render 'MVP2_apply_to_job_post__citi.html', :layout => '__job_seeker_apply_layout'
      
    # Citi job
    elsif params[:job_id].to_i == 215 || params[:job_id].to_i == 112
      render 'MVP2_apply_to_job_post__citi.html', :layout => '__job_seeker_apply_layout'
      
    else
      render 'MVP2_apply_to_job_post.html', :layout => '__job_seeker_apply_layout'
      
    end
  end
      
      
  #
  # -- This method
  #
  # - FINDS
  #   (1) n/a
  #
  # - CHECKS
  #   (1) If user is a JOB SEEKER - is("user__job_seeker") --> [Not a Job Seeker] Creates a User (type = Job Seeker)
  #   (2) If person is a JOB SEEKER - is("person__job_seeker") --> [Not a Job Seeker] Creates a Contact (type = Recruitment Agency)
  #
  # - CREATES
  #   (1) User (type = Job Seeker) - Fs2User
  #   (2) Job Seeker Marketing Funnel - Fs2UserMarketingFunnel
  #   (3) Job Seeker - Fs2JobSeeker
  #   
  def ajax_apply_to_job_post
    
    is_error = false
    @arr = {
          :status => "200",
          :action => "apply_to_job_post",
          :session_ids => {:active_user => ENTITY_TYPES[:job_seeker]},
          :message => nil
        }
    
    begin

      # --- 1. In case the user is already in the system's session, run the match instantly
      
      if is("user__job_seeker")
        # add_ajax_start_up_actions("search_jobs")
        puts "X"
        
      # --- ELSE search entities currently requires a 'user' object, create it temporarily here
      else
        session[:user] = Fs2User.new({
          :user_type_id => Fs2User::USER_TYPES[:job_seeker],
          :status_id => Fs2User::USER_STATUSES[:linkedin_job_post],
          :referral_id => Fs2User::USER_REFERRALS[:applied_once]
        })
        session[:user].save(false)
        @arr[:session_ids][:user_id] = session[:user].id
        
        # Create the funnel
        funnel = Fs2UserMarketingFunnel.new({
          :user_id => session[:user].id,
          :marketing_funnel_id => 1,
          :state_id => 1
        })
        funnel.save(false)
      end
      
      # If the 'session[:person]' doesn't exist, create it from scratch -> it is required by the 'search entities' function
      if is("person__job_seeker")
        
        # --- X. Run the match
        
      else
        session[:person] = Fs2JobSeeker.new({:user_id => id("user__job_seeker")})
        session[:person].save(false)
        @arr[:session_ids][:job_seeker_id] = session[:person].id
      end
      
      
      # --- X. Save the 'skills_profile' object and store its ID in 'session'
      
      fs_profile = save_skills_profile({:job_seeker_id => id("person__job_seeker")})
      raise 'ERROR' if !fs_profile
      
      
      # --- X. Run the match
      
      match_results = _match_job_seeker(id("person__job_seeker"), params[:job_id])
      match_info = match_results[:job_match]
      
      session[:fs_profiles_ids] = {
        :job_seeker => fs_profile.id,
        :job => match_results[:job_match][1][:skills_profile_id]
      }
      @arr[:session_ids][:fs_profiles_ids] = {
        :job_seeker => fs_profile.id,
        :job => match_results[:job_match][1][:skills_profile_id]
      }
      
      # * Temporarily allow all applications to match and go through the process. This will ensure we capture their CVs
      #   and other personal details
      @arr[:above_threshold] = true
      
      # * The core implementation
      # if match_info && match_info[1] && match_info[1][:match_pct].to_i >= 10
        # @arr[:above_threshold] = true
      # else
        # @arr[:above_threshold] = false
      # end
    
    rescue Exception => exc
      
      is_error = true
      
    end
    
    if is_error
      @arr = {
          :status => "50",
          :action => "apply_to_job_post",
          :message => 'Errors were found in the fields below, please check the messages next to each field'
        }
        
      # @arr = {
          # :status => "101",
          # :action => "apply_to_job_post",
          # :message => 'Errors were found in the fields below, please check the messages next to each field',
          # :errors => {
            # :fld_fs_profile => {
              # :error => true,
              # :fields => nil
            # }
          # }
        # }
    end
        
    # +++ TEST
    session[:user] = nil
    session[:person] = nil    
    
    respond_to do |format|
      
      format.json {  
        render :json => @arr.to_json, :callback => params[:callback] 
      }
      
    end    
  end
  
  #
  #
  #
  def prep_json_response(header_params_h, errors)
    
  end
  
  def fajax_job_seeker_sign_up
    
  end
  
  
  
  def fajax_send_job_post_application__validate
    
    is_file_uploaded = upload_files({:upload_cv => [id("person__job_seeker"), ENTITY_TYPES[:job_seeker]]}, true)
    fields = Hash.new
    
    fields[:fields_html_name] = {
      :file_cv => "upload_cv[fs2_file]",
      :email => "register__job_seeker__email",
      :phone => "register__job_seeker__phone"
    }
    
    fields[:fields_as_obj] = {
      :file_cv => @upload_files[:cv],
      :email => Fs2User.new({:email => params[:register__job_seeker__email]}),
      :phone => Fs2JobSeeker.new({:full_name => "{anonymous}", :phone_number_1 => params[:register__job_seeker__phone]})
    }
    
    fields[:fields_invalid] = {
      :file_cv => @upload_files[:cv].errors && !@upload_files[:cv].errors.empty? ? true : false,
      :email => !fields[:fields_as_obj][:email].valid?,
      :phone => !fields[:fields_as_obj][:phone].valid?
    }
    
    # --- June 2013 deployment note ---
    #   Having differences between development and production environments re: checking duplicate records
    #   For now, it's ignored
    # --------------------------------
    # if fields_invalid[:email]
      # email_errors = fields_as_obj[:email].errors.on(:email)
      # if email_errors
#           
        # # In case the email is a duplicate, locate the existing user_id
#           
        # if email_errors == Fs2User::VALIDATION_MESSAGES[:already_exists]
#             
          # fields_as_obj[:email].errors.clear
          # fields_invalid[:email] = false
          # existing_user = Fs2User.find_by_email(fields_as_obj[:email].email)
          # existing_job_seeker = Fs2JobSeeker.find_by_user_id(existing_user.id)
#             
          # # Update the phone number with the number inserted last
          # existing_job_seeker.update_attributes({:phone_number_1 => fields_as_obj[:phone].phone_number_1})
#             
        # elsif email_errors.index(Fs2User::VALIDATION_MESSAGES[:already_exists])
#             
          # email_errors.delete(Fs2User::VALIDATION_MESSAGES[:already_exists])
          # existing_user = Fs2User.find_by_email(fields_as_obj[:email].email)
#             
        # end
      # end
    # end
    
    
    # --- Generate the 'client-facing' / AJAX error messages
    
    fields[:fields_invalid].each do |field_name, invalid|
      if invalid
        
        @arr[:errors] = {} if @arr[:errors].nil?
        
        fields[:fields_as_obj][field_name].errors.each do |attr, message|
          # puts '----- ERROR: ' + attr + ' : ' + message
          
          @arr[:errors][fields[:fields_html_name][field_name]] = {} if @arr[:errors][fields[:fields_html_name][field_name]].nil?
          @arr[:errors][fields[:fields_html_name][field_name]][attr] = [] if @arr[:errors][fields[:fields_html_name][field_name]][attr].nil?
          @arr[:errors][fields[:fields_html_name][field_name]][attr] << message
        end
      end
    end
    
    raise 'Error' if @arr[:errors] && !@arr[:errors].empty?
    
    fields
    
  end
  
  
  def fajax_send_job_post_application__existing_user(existing_user, funnel)
    
    # Delete 'new' one (one just created) - including the 'funnel'
    Fs2User.connection.execute("delete from fs2_users where id = " + id("user__job_seeker").to_s) if existing_user && id("user__job_seeker")
    
    
    # session[:user] = existing_user
    # session[:person] = existing_job_seeker if existing_job_seeker
    
    @arr[:session_ids][:user_id] = params[:user_id] = existing_user.id
    
    # Find the 'real' funnel again
    existing_funnel = Fs2UserMarketingFunnel.find_by_user_id(id("user__job_seeker"))
    
    if existing_funnel
      
      # --- 1. Remove 'newly created' funnel
      Fs2UserMarketingFunnel.connection.execute("delete from fs2_user_marketing_funnels where id = " + funnel.id.to_s) if funnel
      
      # --- 2. Set the 'funnel' pointer to the 'existing funnel'
      funnel = existing_funnel
      
    else
      
      # --- X. Retain 'newly created' funnel object (= do nothing)
      
    end
    
    funnel
    
  end
  
  
  def fajax_send_job_post_application__new_user(fields)
    
    # --- X. No existing user, make sure the new object is properly filled-out
    
    # 'EMAIL' attribute update - init the 'fs2_user' and update its email address
    new_user_obj = Fs2User.find_by_id(params[:user_id])
    new_user_obj.update_attributes({:email => fields[:fields_as_obj][:email].email})
    
    # 'PHONE NUMBER' attribute update - init the 'fs2_job_seeker' and update its phone_number attribute
    new_job_seeker_obj = Fs2JobSeeker.find_by_id(params[:job_seeker_id])
    new_job_seeker_obj.update_attributes({
      :full_name => fields[:fields_as_obj][:phone].full_name,
      :phone_number_1 => fields[:fields_as_obj][:phone].phone_number_1
    })
    
  end  
  

  def fajax_send_job_post_application__notify
    
    # ********************************
    # UPDATE the notifications table
    
    # Retrieve the JOB object and its USER IDs (for the notifications table)
    job = fetch_job_profile(
      params[:job_id],
      nil,
      {:include_skills_profile => true})
      
    if job
      contact_user_id = job[:company_contact_user_obj].id.to_i if job[:company_contact_user_obj]
      agent_user_id = job[:agency_contact_user_obj].id.to_i if job[:agency_contact_user_obj]
    end   
    
    # Store the company user_id
    if contact_user_id
      notify = Fs2UserNotification.new({ :user_id => contact_user_id, :entity_name => 'job_application' })
      notify.save(false)
    end
    
    # Store the agency user_id (if exists and if different from company user_id = sometimes for debugging I used the same user_id)
    if agent_user_id && ( contact_user_id.nil? || agent_user_id != contact_user_id )
      notify = Fs2UserNotification.new({ :user_id => agent_user_id, :entity_name => 'job_application' })
      notify.save(false)
    end
    # ********************************
    
  end
  
  
  def fajax_send_job_post_application__send_email
    
    # --- Send an email to the recruiter, with the matching and the CV
    
    is_email_to_recruiter_sent = email__recruiter__application_with_cv(
      id("person__job_seeker"), 
      params[:job_id], 
      Fs2Mailer::EMAIL_TYPES[:apply_from_social_job_post])
      
    is_email_to_job_seeker_sent = email__job_seeker__application_sent(
      id("person__job_seeker"), 
      params[:job_id], 
      Fs2Mailer::EMAIL_TYPES[:apply_from_social_job_post]
    )
    
    raise 'Error' if !is_email_to_recruiter_sent || !is_email_to_job_seeker_sent
    
  end
  
  
  def fajax_send_job_post_application__create_job_application
    
    job_application = Fs2JobApplication.new({
      :job_seeker_fs_profile_id => id("job_seeker__fs_profile"),
      :job_fs_profile_id => id("job__fs_profile"),
      :status_id => Fs2JobApplication::STATUSES[:sent]
    })
    job_application.save(false)
    
  end  
  
  
  def fajax_send_job_post_application__job_seeker(existing_user, fields)
    
    # --- X. Check the 'job seeker' object
    
    existing_job_seeker = Fs2JobSeeker.find_by_user_id(existing_user.id)
    
    if existing_job_seeker
      # Delete the 'just created' one
      Fs2JobSeeker.connection.execute("delete from fs2_job_seekers where id = " + id("person__job_seeker").to_s) if existing_job_seeker
      
      @arr[:session_ids][:job_seeker_id] = params[:job_seeker_id] = existing_job_seeker.id
      
      # Update the 'existing' one (phone number) and swap the files' entity_id
      existing_job_seeker.update_attributes({:phone_number_1 => fields[:fields_as_obj][:phone].phone_number_1})
      fields[:fields_as_obj][:file_cv].update_attributes({:entity_id => existing_job_seeker.id})
      
      # --- X. Re-assign the newly created 'fs_profile' object to the user
      attach_fs_profile_to_entity(id("job_seeker__fs_profile"), id("person__job_seeker"), ENTITY_TYPES[:job_seeker])
      
    else
      
      # * This is a fix to a database error (assumed - not fully tested)
      #  In case the 'fs_user' exists but the job seeker doesn't, we need to attach the 'newly' created 'job_seeker' object
      #  to the existing user
      new_job_seeker_obj = Fs2JobSeeker.find(params[:job_seeker_id])
      new_job_seeker_obj.update_attributes({
        :full_name => fields[:fields_as_obj][:phone].full_name,
        :user_id => existing_user.id,
        :phone_number_1 => fields[:fields_as_obj][:phone].phone_number_1
      })
      
    end
        
  end
  
  
  #
  # -- This method
  #
  # - FINDS
  #   (1) Funnel (of temporary user - for Visitor, from 'ajax_apply_to_job_post' step) - Fs2UserMarketingFunnel (by the user_id)
  #   (2) User (existing user) - Fs2User (by email)
  #   (3) Funnel (of existing user found by email) - Fs2User (by email)
  #   (4) Job Seeker (of existing user) - Fs2JobSeeker (by existing user_id)
  #   (5) Job - Fs2Job (by the job_id) - for the email notifications
  # 
  # - CHECKS
  #   (1) CV, User & Job Seeker fields are VALID
  #   (2) Existing user (by email)
  #   (3) Existing funnel (by existing user_id)
  #   (4) Existing Job Seeker (by existing user_id)
  #
  # - CREATES
  #   (1) CV - Fs2File
  #   (2) User [Validation] - Fs2User
  #   (3) Job Seeker [Validation] - Fs2JobSeeker
  #   (4) Job Application - Fs2JobApplication (include: job_seeker 5Skills profile + job 5Skills profile)
  #
  # - DELETES
  #   (1) User [created for validation, created in this method] (if existing user found by email)
  #   (2) Funnel [temporary, created in the 'ajax_apply_to_job_post' step] (if existing funnel was found)
  #   (3) Job Seeker [created for validation, created in this method] (if existing user found by email)
  #
  # - SETS
  #   (1) session_ids.job_seeker_id = existing job seeker (if existing found)
  #   (2) Attach new 5Skills profile to existing job_seeker (if existing user found)
  #   (3) [No existing user found - use new User created] Update fields (Name, Phone, Email)
  #  
  def fajax_send_job_post_application
    
    #TODO: Treat a scenario where the user waited on the 'send application' screen too long (session timed out)
    #  OR cleared the cache / cookies and then they hit 'apply'
    #  The system needs to regenerate the user objects
    
    # Initial state = Success - optimistic
    @arr = {
        :status => "200",
        :session_ids => {
          :active_user => ENTITY_TYPES[:job_seeker],
          :job_seeker_id => params[:job_seeker_id],
          :user_id => params[:user_id],
        },
        :action => "send_application"
      }

    
    begin
      
      
      existing_user = existing_job_seeker = nil
      
        
      # --- X - VALIDATE (+ Get the Funnel and check if there is an EXISTING USER)
      
      fields = fajax_send_job_post_application__validate      
      funnel = Fs2UserMarketingFunnel.find_by_user_id(id("user__job_seeker"))      
      existing_user = Fs2User.find_by_email(fields[:fields_as_obj][:email].email) if fields[:fields_as_obj][:email].email && !fields[:fields_as_obj][:email].email.blank?
      
      
      if existing_user # --- X - EXISTING USER (+ Funnel)

        funnel = fajax_send_job_post_application__existing_user(existing_user, funnel)
        fajax_send_job_post_application__job_seeker(existing_user, fields)

        
      else # --- X - NEW USER
        
        fajax_send_job_post_application__new_user(fields)
        
      end
      
      
      # --- X. Create the Fs2JobApplication object
      
      fajax_send_job_post_application__create_job_application
      fajax_send_job_post_application__notify  # -- NOTIFY
      funnel.update_attributes({:user_id => id("user__job_seeker"), :state_id => 2}) if funnel.state_id < 2  # -- UPDATE FUNNEL
      fajax_send_job_post_application__send_email  # -- SEND EMAIL
      
      
    rescue Exception => exc
      
      @arr[:status] = "101"
      
    end
    
    render_js_parent(@arr.to_json)
    
  end  
  
  def create_job_seeker_profile
    render 'create_job_seeker_profile.html', :layout => 'fs_layout_job_seeker_profile_create'
  end
  
  def view_job_seeker_profile
    
    if !params[:job_seeker_id]
      flash[:error] = 'No "job_seeker_id" provided!'
      render 'view_job_seeker_profile.html', :layout => 'fs_layout_job_seeker_profile'
      return
    end
    
    # --- If USER is not a 'job_seeker' and a JOB exists in session
    # Make sure to grab the 'job' details and perform a match
    if session[:user].user_type_id != Fs2User::USER_TYPES[:job_seeker] && session[:jobs]
      @job_seeker = fetch_job_seeker_profile(params[:job_seeker_id], session[:jobs][:active_job_id])
    else
      @job_seeker = fetch_job_seeker_profile(params[:job_seeker_id], nil)  
    end
    
    @fs_profiles = @job_seeker[:fs_profiles]
    set_active_fs_profile
    
    render 'view_job_seeker_profile.html', :layout => 'fs_layout_job_seeker_profile'
  end
  
  def edit_job_seeker_profile
    
    @job_seeker = fetch_job_seeker_profile(params[:job_seeker_id])
    @fs_profiles = @job_seeker[:fs_profiles]
    set_active_fs_profile
    
    add_ajax_start_up_actions("search_jobs")
    
    render 'maintain_job_seeker_profile.html', :layout => 'fs_layout_job_seeker_profile_edit'
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
  
  def manage_social_posting
    @arr = {
      :status => "200",
      :action => "manage_social_posting"
    }
    
    respond_to do |format|
      
      format.json {  
        render :json => @arr.to_json, :callback => params[:callback] 
      }
      
    end
  end
  
  def ajax_save_job_seeker_fs_profile
    update_skills_profile = true
    @arr = {
      :status => "200",
      :action => "save_job_seeker_fs_profile"
    }
    
    Fs2SkillsProfile.transaction do
          
      begin
        
        case params[:status_id]
          
          when Fs2User::USER_STATUSES[:at_landing_page]
            update_skills_profile = false
          
          when Fs2User::USER_STATUSES[:completed_3_skills]
            session[:user].update_attributes({:status_id => params[:status_id]})
            
            session[:person] = Fs2JobSeeker.new({:user_id => session[:user].id})
            session[:person].save(false)
            
            @arr[:data] = {:job_seeker_id => session[:person].id}
            
          when Fs2User::USER_STATUSES[:first_profile_update]
            
              
        end
        
        return if !session[:user].user_type_id == Fs2User::USER_TYPES[:job_seeker]
            
        # Destroy the current 'skills_profile' object and its children (and create a brand new object)
        # AND destroy current 'matches' (delete all 'fs2_skills_profiles_matches' entities with
        # matching job_seeker_id
        
        if update_skills_profile && session[:person]
          skills_profile = save_skills_profile({:job_seeker_id => session[:person].id})
          raise 'ERROR' if !skills_profile
          
          # upload_files({:upload_cv => session[:person].id}, true)
          # upload_files({:upload_profile_photo => @current_job_seeker.id}, true)
        
        end
      
        
      rescue Exception => exc
        
        # @job_seeker = @temp_job_seeker if @temp_job_seeker
        
        flash[:error] = 'Errors were found in the fields below, please check the messages next to each field'
        
        @arr = {
            :status => "101",
            :action => "save_job_seeker_fs_profile",
            :message => 'Errors were found in the fields below, please check the messages next to each field'
          }
                  
      end # rescue
    end # transaction
    
    respond_to do |format|
      
      format.json {  
        render :json => @arr.to_json, :callback => params[:callback] 
      }
      
    end
    
  end
  
  def tmp_ajax
        # ************************************************
        #  1 >  Run the search - make sure the latest information and match information is captured and stored
        # ************************************************
        
        # -------- The following will be based on reading matching information from session --------
        search_entities(ENTITY_TYPES[:job], {:contact_details => true})
        
        
        # ************************************************
        #  2 >  Save the matches (with status "NEW")
        # ************************************************
        
        # -------- The following will be based on reading matching information from session --------
        if @js_results_array
          
          # ************************************************
          #  3 >  Get the 'job_seeker' files
          # ************************************************
          job_seeker_summary = {} # object used for sending and receiving emails
           
          if params[:send_emails]
            
            prep_files(session[:person].id, [Fs2File::FILE_TYPES[:profile_photo]])
            
            js_hash = {}
            job_seeker_summary[:files] = {}
            job_seeker_summary[:full_name] = session[:person].full_name
                              
            if @upload_files[:profile_photo]
              job_seeker_summary[:files][:profile_photo] = {
                :id => @upload_files[:profile_photo].id,
                :small_dimensions => @upload_files[:profile_photo].small_dimensions,
                :medium_dimensions => @upload_files[:profile_photo].medium_dimensions}
            end
            
            transaction_h = {:email_type => Fs2Mailer::EMAIL_TYPES[:new_job_seeker_matches]}
            
          end
          
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
            
            if params[:send_emails]
              job_seeker_summary[:cv_trans_status_id] = job[1][:cv_trans_status_id]
              job_seeker_summary[:cv_trans_status_name] = job[1][:cv_trans_status_name]
              job_seeker_summary[:cv_trans_updated_at] = job[1][:cv_trans_updated_at]
              job_seeker_summary[:cv_trans_updated_at_formatted] = job[1][:cv_trans_updated_at_formatted]
              job_seeker_summary[:cv_trans_updated_at_time_ago] = job[1][:cv_trans_updated_at_time_ago]
            end
            
            match.save(false)
            
            if params[:send_emails]
            
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
              
          end # iteration over search results
          
        end    
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
  
  def send_cv_to_job
    send_cv_emails(Fs2Mailer::EMAIL_TYPES[:cv_sent_for_job])
  end  
  
  def cv_request_approve
    send_cv_emails(Fs2Mailer::EMAIL_TYPES[:cv_request_approved_for_job])
  end
  
  def cv_request_reject
    send_cv_emails(Fs2Mailer::EMAIL_TYPES[:cv_request_rejected_for_job])
  end     
  
end
