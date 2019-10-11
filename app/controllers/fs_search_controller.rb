#
# Main 5skills search method / algorithm
#
# SEARCH LOGIC:
# -------------
#
#  1. 'search_entities': Search all JOBS or JOB SEEKERS for any entity that has ONE or MORE of the entered keywords
#         in any one of the 3 fields: primary skill, sub skill or general keywords
#
#  2. 'search_entities_create_results': Main method for initializing, populating and matching the entities
#         to the entered skills
#
#  3. 'search_entities_populate_entity_values': Called while iterating each found 'entity'. This method
#         assigns the 'full_name', 'status' etc values to the '@js_profiles' CLIENT result-set
#
#  4. 'search_entities_populate_keyword_ids': Populates the supporting MATRIX with ONLY keyword ids
#
#  5. 'search_entities_populate_entity_files': Prepare the relevant FILES for CLIENT usage
#
#  6. *** 'search_entities_perform_matches_pct': Perform the matching
#
#  7. 'search_entities_sort_matches_pct': Sort the CLIENT result set
# 

require "benchmark"

class FsSearchController < FsBaseController
  
  def create_sql_field_map( data, flags )
    
    search_sql_map = {
      
      :job_seeker => {
        :select => 
          " js.id, js.full_name, js.anonymous js_anonymous, js.looking_for_work js_looking_for_work" + 
          ", f.id f_id, f.file_type f_ft, f.small_dimensions f_sd, f.medium_dimensions f_md",
        :select_contact_details => 
          ", js_user.id js_user_id, js_user.email js_user_email",
        :from => 
          " fs2_skills_profiles sp" + 
          " LEFT JOIN fs2_job_seekers js on (js.id = sp.entity_id)",
        :from_files =>
          " LEFT JOIN fs2_files f on (js.id = f.entity_id)",
        :from_job_applications =>
          " LEFT JOIN fs2_job_applications job_app on (job_app.job_seeker_fs_profile_id = sp.entity_id)",          
        :from_contact_details =>
          " LEFT JOIN fs2_users js_user on (js.user_id = js_user.id)",
        :where =>
          " js.id IS NOT NULL",
          
        :select_current_positions => 
          ", js_positions.title js_title",
        :from_cvs =>
          " LEFT JOIN fs2_cvs js_cv on (js.id = js_cv.job_seeker_id)", 
        :from_current_positions =>
          " LEFT JOIN fs2_cv_positions js_positions on (js_cv.id = js_positions.cv_id)",
        :where_current_positions =>
          " AND js_positions.is_current = 1",
          
        :select_user_connector => 
          ", js_connector.linkedin_public_profile_url js_linkedin_url",
        :from_user_connector =>
          " LEFT JOIN fs2_user_connectors js_connector on (js.user_id = js_connector.user_id)",
      },
        
      :job => {
        :select => 
          " j.id, j.title j_title",
        :select_company_details => 
          ", j_comp.name j_comp_name",
        :select_company_files =>
          ", j_comp_f.id j_comp_logo_id, j_comp_f.file_type j_comp_logo_ft, j_comp_f.small_dimensions j_comp_logo_sd, j_comp_f.medium_dimensions j_comp_logo_md",
        :select_company_contact_details => 
          ", j_comp_user.id j_comp_user_id, j_comp_contact.full_name j_comp_contact_full_name, j_comp_user.email j_comp_user_email",
        :select_agency_details => 
          ", j_agen.name j_agen_name",
        :select_agency_files =>  
          ", j_agen_f.id j_agen_logo_id, j_agen_f.file_type j_agen_logo_ft, j_agen_f.small_dimensions j_agen_logo_sd, j_agen_f.medium_dimensions j_agen_logo_md",
        :select_agency_contact_details =>
          ", j_agen_user.id j_agen_user_id, j_agen_contact.full_name j_agen_contact_full_name, j_agen_user.email j_agen_user_email",
        :from => 
          " fs2_skills_profiles sp" + 
          " LEFT JOIN fs2_jobs j on (j.id = sp.entity_id)",
        :from_company_details =>
          " LEFT JOIN fs2_organisations j_comp on (j.company_id = j_comp.id)",
        :from_company_files =>
          " LEFT JOIN fs2_files j_comp_f on (j.company_id = j_comp_f.entity_id)",
        :from_company_contact_details =>
          " LEFT JOIN fs2_contacts j_comp_contact on (j.company_contact_id = j_comp_contact.id)" +
          " LEFT JOIN fs2_contacts j_agen_contact on (j.agency_contact_id = j_agen_contact.id)",
        :from_agency_details =>
          " LEFT JOIN fs2_organisations j_agen on (j.agency_id = j_agen.id)",
        :from_agency_files =>
          " LEFT JOIN fs2_files j_agen_f on (j.agency_id = j_agen_f.entity_id)",
        :from_agency_contact_details =>
          " LEFT JOIN fs2_users j_comp_user on (j_comp_contact.user_id = j_comp_user.id)" +
          " LEFT JOIN fs2_users j_agen_user on (j_agen_contact.user_id = j_agen_user.id)",
        :where =>
          " j.id IS NOT NULL"
      },
      
      :fs_profile => {
        :select => 
          ", sp.id sp_id, sp.updated_at sp_updated_at, sp.entity_id, sp.entity_type, sp.profile_type" + 
          ", s.keyword_id s_kid, s_k.keyword s_keyword, s.priority sp, s.years_experience, s.self_rate" + 
          ", sd.keyword_id sd_kid, sd_k.keyword sd_keyword, sd.priority sdp" + 
          ", ar.keyword_id ar_kid, ar_k.keyword ar_keyword, ar.priority arp, sp.display_matrix sp_display_matrix",
        :from => 
          " LEFT JOIN fs2_skills s on (sp.id = s.skills_profile_id)" +
          " LEFT JOIN fs2_keywords s_k on (s.keyword_id = s_k.id)" +
          " LEFT JOIN fs2_skill_details sd on (s.id = sd.skill_id)" + 
          " LEFT JOIN fs2_keywords sd_k on (sd.keyword_id = sd_k.id)" + 
          " LEFT JOIN fs2_additional_requirements ar on (sp.id = ar.skills_profile_id)" +
          " LEFT JOIN fs2_keywords ar_k on (ar.keyword_id = ar_k.id)",
        :where_id =>
          " sp.id = " + data[:fs_profile_id].to_s,
        :where_job_seeker => {
          :match_with_job_id =>
            " AND sp.entity_id = " + data[:match_with_job_id].to_s,
        },
        :where_job => {
          :match_with_job_seeker_id =>
            " AND sp.entity_id = " + data[:match_with_job_seeker_id].to_s
        },
        :where_fs_profile_types => {
          :user_profile_job_seeker => 
            " AND ( sp.entity_type = #{ENTITY_TYPES[:job_seeker]} and sp.profile_type = #{FS_PROFILE_TYPES[:user_profile]} )",
          :user_profile_job =>
            " AND ( sp.entity_type = #{ENTITY_TYPES[:job]} and sp.profile_type = #{FS_PROFILE_TYPES[:user_profile]} )",
          :template =>
            " AND ( sp.profile_type = #{FS_PROFILE_TYPES[:template]} )",
          :demo =>
            " AND ( sp.profile_type = #{FS_PROFILE_TYPES[:demo]} )",
          :search =>
            " AND ( sp.profile_type = #{FS_PROFILE_TYPES[:search]} )",
        }
      },
      
      :cv_transactions => {
        :select => 
          ", ctjt.status_id cv_trans_status_id, ctjt.updated_at cv_trans_updated_at",
        :from_job_seeker => 
          " LEFT JOIN (select a.* from fs2_cvs_to_jobs_transactions a where a.job_id = " + data[:cv_transactions_job_id].to_s + ") ctjt on (js.id = ctjt.job_seeker_id)",
        :from_job => 
          " LEFT JOIN (select a.* from fs2_cvs_to_jobs_transactions a where a.job_seeker_id = " + data[:cv_transactions_job_seeker_id].to_s + ") ctjt on (j.id = ctjt.job_id)"
      }
      
    }
      
    if flags[:search_single_entity].nil?
      
      search_sql_map[:keyword_search] = {
        :where_skills_and_sub_skills =>
          " AND ( sp.id in (" + 
          " select" +
          " DISTINCT s.skills_profile_id" +
          " from" +
          " fs2_skills s" +
          " LEFT JOIN fs2_skill_details sd on (sd.skill_id = s.id)" +
          " where" + 
          " s.keyword_id in (" + data[:skill_names_ids_arr] + ")" +
          " OR sd.keyword_id in (" + data[:skill_names_ids_arr] + ") )",
        :where_general_skills =>
          " OR sp.id in (" +
          " select DISTINCT ar.skills_profile_id" +
          " from" +
          " fs2_additional_requirements ar" +
          " where" +
          " ar.keyword_id in (" + data[:skill_names_ids_arr] + ") ) )"
      }
      
    end
    
    search_sql_map
    
  end
  
  def create_executable_sql(search_sql_map, flags)
    
    
    # --- JOB SEEKER
    
    if flags[:entity_type] == ENTITY_TYPES[:job_seeker]
      
      sql = "select"  
      sql += search_sql_map[:job_seeker][:select]
      sql += search_sql_map[:job_seeker][:select_contact_details] if flags[:include_contact_details]
      sql += search_sql_map[:job_seeker][:select_current_positions]
      sql += search_sql_map[:job_seeker][:select_user_connector]
      sql += search_sql_map[:fs_profile][:select]
      sql += search_sql_map[:cv_transactions][:select] if flags[:include_cv_transactions]
      
      sql += " from"
      sql += search_sql_map[:job_seeker][:from]
      sql += search_sql_map[:job_seeker][:from_files]
      sql += search_sql_map[:job_seeker][:from_contact_details] if flags[:include_contact_details]
      sql += search_sql_map[:job_seeker][:from_cvs]
      sql += search_sql_map[:job_seeker][:from_current_positions]
      sql += search_sql_map[:job_seeker][:from_user_connector]
      sql += search_sql_map[:fs_profile][:from]
      sql += search_sql_map[:cv_transactions][:from_job_seeker] if flags[:include_cv_transactions]
      
      sql += " where"
      sql += search_sql_map[:job_seeker][:where]
      sql += search_sql_map[:job_seeker][:where_current_positions]
      sql += search_sql_map[:fs_profile][:where_fs_profile_types][:user_profile_job_seeker]
      
      if flags[:search_single_entity]
        sql += search_sql_map[:fs_profile][:where_job][:match_with_job_seeker_id]
      else
        sql += search_sql_map[:keyword_search][:where_skills_and_sub_skills]
        sql += search_sql_map[:keyword_search][:where_general_skills]
      end
      
      sql += " order by"
      sql += " sp.entity_id asc"
    
    
    # --- JOB
    
    elsif flags[:entity_type] == ENTITY_TYPES[:job]
      
      # ------------------ SELECT ------------------
      
      sql = "select"  
      sql += search_sql_map[:job][:select]
      sql += search_sql_map[:job][:select_company_details]
      sql += search_sql_map[:job][:select_company_files]
      sql += search_sql_map[:job][:select_agency_details]
      sql += search_sql_map[:job][:select_agency_files]
      
      if flags[:include_contact_details]
        sql += search_sql_map[:job][:select_company_contact_details]
        sql += search_sql_map[:job][:select_agency_contact_details]  
      end
      
      sql += search_sql_map[:fs_profile][:select]
      sql += search_sql_map[:cv_transactions][:select] if flags[:include_cv_transactions]
      
      # ------------------ FROM ------------------
      
      sql += " from"
      sql += search_sql_map[:job][:from]
      sql += search_sql_map[:job][:from_company_details]
      sql += search_sql_map[:job][:from_company_files]
      sql += search_sql_map[:job][:from_agency_details] 
      sql += search_sql_map[:job][:from_agency_files]
      
      if flags[:include_contact_details]
        sql += search_sql_map[:job][:from_company_contact_details] 
        sql += search_sql_map[:job][:from_agency_contact_details]  
      end
      
      sql += search_sql_map[:fs_profile][:from]
      sql += search_sql_map[:cv_transactions][:from_job] if flags[:include_cv_transactions]
      
      
      # ------------------ WHERE ------------------
      
      sql += " where"
      sql += search_sql_map[:job][:where]
      sql += search_sql_map[:fs_profile][:where_fs_profile_types][:user_profile_job]
      
      if flags[:search_single_entity]
        sql += search_sql_map[:fs_profile][:where_job_seeker][:match_with_job_id]
      else
        sql += search_sql_map[:keyword_search][:where_skills_and_sub_skills]
        sql += search_sql_map[:keyword_search][:where_general_skills]
      end

      
      # ------------------ ORDER BY ------------------

      sql += " order by"
      sql += " sp.entity_id asc, sp.id desc, sp.updated_at desc"
    
    end
    
    sql
    
  end
    
  def execute_sql(executable_sql, flags)
    
    if flags[:entity_type] == ENTITY_TYPES[:job_seeker]
      results_from_db = Fs2JobSeeker.find_by_sql(executable_sql)
    elsif flags[:entity_type] == ENTITY_TYPES[:job]
      results_from_db = Fs2Job.find_by_sql(executable_sql)
    end
    
    results_from_db
    
  end
  
  def do_search_2(data, flags)
    
    return if flags[:search_single_entity].nil? && data[:request_fs_profile][:skill_names_ids_map].empty?
    
    # 0 --- Set the defaults
    
    flags[:include_contact_details] = false if flags[:include_contact_details].nil?
    flags[:include_cv_transactions] = false if flags[:include_cv_transactions].nil?
    
    
    # 1 --- Build the SQL statement
    
    sql_field_map = nil
    data[:cv_transactions_job_id] = 17 
    data[:cv_transactions_job_seeker_id] = 186
    
    if flags[:search_single_entity].nil?
      data[:skill_names_ids_arr] = data[:request_fs_profile][:skill_names_ids_map].values.join(",")
    end
      
    sql_field_map = create_sql_field_map( data, flags )
    executable_sql = create_executable_sql( sql_field_map, flags )
    
    
    # 2 --- Execute the search
    
    results_from_db = execute_sql( executable_sql, flags )
       
    
    # 3 --- Process the search results
    
    return if results_from_db.nil?
    
    data[:results_from_db] = results_from_db
    search_entities_create_results( data, flags )
        
  end
  
  
  # ------------------- CORE [17 Oct 2013] --- DOWN
  #
  
  def ___get_match_weights
    match_weights = {
      :skill_industry => 3,
      :skill_category => 4,
      :skill => {
        :rel_1 => 11,
        :rel_2 => 9,
        :rel_3 => 4
      },
      :skill_years_exp => 5,
      :_max_score => 23
    }
  end
  
  def ___generate_sql_by_skills(skills, match_weights)
    
  end
  
  def ___generate_sql_by_fs_profile(data_fs_profile, match_weights)
    
    # Combine skills, related_strong and related_some skills into one big array
    all_skills = data_fs_profile[:_lists][:skills] + data_fs_profile[:_lists][:related_strong] + data_fs_profile[:_lists][:related_some]
    all_skills = (all_skills.collect { |skill| skill[0] if skill && skill[0] }).compact.uniq


    sql = "SELECT" +
      " DISTINCT" + 
      " fs_profile_id," +
      " skill_industry_id," +
      " skill_category_id," +
      " skill_id," +
      " skill_rel_strength," +
      " skill_years_exp," +
      " skill_priority"
    
    # -- Iterate through the number of skills in the 'fs_profile' object
    #NEXT: Add additional parameters for matching
    data_fs_profile[:skills].length.times do |i|
    
      # -- INDUSTRY
      
      if data_fs_profile[:skills][i][:industry]            
        sql += ", " + ___generate_select_other_columns({
          :_priority => i + 1, :_type => :skill_industry, :industry_id => data_fs_profile[:skills][i][:industry][0]},
          match_weights[:skill_industry])
      end
      
      # -- CATEGORY
      
      if data_fs_profile[:skills][i][:category]
        sql += ", " + ___generate_select_other_columns({
          :_priority => i + 1, :_type => :skill_category, :category_id => data_fs_profile[:skills][i][:category][0]},
          match_weights[:skill_category])
      end
      
      # -- SKILL
      
      sql += ", " + ___generate_select_other_columns({
        :_priority => i + 1, :_type => :skill, :skill_id => data_fs_profile[:skills][i][:skill][0], :rel_strength => 1},
        match_weights[:skill][:rel_1])
      
      # -- RELATED (STRONG)
      
      if data_fs_profile[:skills][i][:related_strong]
        data_fs_profile[:skills][i][:related_strong].each do |related_skill|
          sql += ", " + ___generate_select_other_columns({
            :_priority => i + 1, :_type => :skill, :skill_id => related_skill[0], :rel_strength => 2},
            match_weights[:skill][:rel_2])
        end
      end
      
      # -- RELATED (SOME)
      
      if data_fs_profile[:skills][i][:related_some]
        data_fs_profile[:skills][i][:related_some].each do |related_skill|
          sql += ", " + ___generate_select_other_columns({
            :_priority => i + 1, :_type => :skill, :skill_id => related_skill[0], :rel_strength => 3},
            match_weights[:skill][:rel_3])
        end
      end
        
    end
    
    # -- FROM, WHERE clauses
    
    sql += " from" +
        " fs2_algorithm_handles" +
      " where" +
        " (" +
          " skill_industry_id IN (#{data_fs_profile[:_lists][:industries].collect { |industry| industry[0] }.split(',')})" +
          " OR skill_category_id IN (#{data_fs_profile[:_lists][:categories].collect { |category| category[0] }.split(',')})" +
          " OR skill_id IN (#{all_skills.split(',')})" +
        " )" +
        " AND skill_priority < 6" +
        " AND fs_profile_id <> #{data_fs_profile[:id]}" +
      " order by" + 
        " fs_profile_id asc" + 
        ", skill_priority asc" + 
        ", skill_rel_strength asc;"
        
    sql
    
  end
  
  def ___search(what = [], by = {}, actions = [], data = {})
    
    # -- Set the weights (hard coded at this point)
    match_weights = ___get_match_weights
    results = []
    
    
    if by[:fs_profile_id]
      
      # 
      # - Ignore the 'fs_profile_id' requested
      
      # Check if an fs_profile object was provided (to avoid additional queries)
      if data[:fs_profile]
        
        
        # -- AA - Perform the search & pct match --> using the 'fs2_algorithm_handles' table
        
        sql = ___generate_sql_by_fs_profile(data[:fs_profile], match_weights)
        results_from_db = Fs2AlgorithmHandle.connection.execute(sql)
        
        return null if results_from_db.nil?
    
    
        # -- 1 - PROCESS RESULTS

        results_i = -1
        prev_fs_profile_id = nil
        fs_profile_ids = []
        
        matrix_sum_scores = nil # -- Holds 2-dimensional SUM scores
        matrix_hits = nil # -- Holds 2-dimensional FLAGS ('1' or '0')
        matrix_scores = nil
        _result_data = nil
        
        
        # -- 2 Iterate ROWS
        
        results_from_db.each_hash do |hash|
          
          res_key = hash['skill_priority'].to_i - 1
          
          
          # -- 3 - INITIALIZE FS-PROFILE object --> at iteration start OR once the 'fs_profile_id' changes
          
          if hash['fs_profile_id'] != prev_fs_profile_id
            
            if !prev_fs_profile_id.nil?
              
              _scores_grouped = {}
              matrix_scores.each do |e|
                if _scores_grouped[e[:_pos]].nil?
                  _scores_grouped[e[:_pos]] = {
                    :_top_score => nil,
                    :scores => []
                  }                  
                end
                
                _scores_grouped[e[:_pos]][:scores] << e
                _scores_grouped[e[:_pos]][:_top_score] = e[:_top_score] if _scores_grouped[e[:_pos]][:_top_score].nil? || e[:_top_score] > _scores_grouped[e[:_pos]][:_top_score]
              end
              
              _pct = ___calculate_pct(matrix_sum_scores, match_weights)
              results[results_i][1] = {
                :_pct => [ _pct, (_pct * 100).round.to_s + '%' ],
                :_hits => matrix_hits,
                :_sum_scores => matrix_sum_scores,
                :_scores => _scores_grouped,
                :skills => _result_data[:skills]
              }
              
              # puts ' _____ ' + _pct.to_s
            end
            
            
            # -- INITIALIZE a new FS_PROFILE
             
            prev_fs_profile_id = hash['fs_profile_id']
            results_i += 1
            fs_profile_ids << prev_fs_profile_id
            
            results[results_i] = []
            results[results_i][0] = hash['fs_profile_id']
            
            matrix_sum_scores = []
            matrix_hits = []
            matrix_scores = []
            
            
            # -- 4a - INITIALIZE '_result_data' object --> a SET of ROWS (multiple & duplicate priority rows)
            
            _result_data = { :skills => [] }
              
          end
          
          
          # -- 4b - POPULATE the '_result_data' object with the REL_1 information (the primary SKILL)
          
          if hash['skill_rel_strength'].to_i == 1

            _result_data[:skills][res_key] = {
              :industry => [ hash['skill_industry_id'].to_i, nil ],
              :category => [ hash['skill_category_id'].to_i, nil ],
              :skill => [ hash['skill_id'].to_i, nil ],
              :years_exp => [ hash['skill_years_exp'].to_i ]
            }
            
          end
          
          prev_search_priority = nil
        
        
          # -- 5 - Iterate COLUMNS
            
          hash.each do |key, value|
            
            # -- 6 - IDENTIFY 's{priority}_{data}' columns
            
            if key =~ /^s\d/
              
              # Extract the key
              req_arr = key.split('_')
              req_key = req_arr[0][1..-1].to_i - 1
              req_column_id = req_arr[1]
              
              
              # CHANGE OF COLUMN -> new priority --> Initialize a new entity
              if req_key != prev_search_priority
                
                matrix_scores << {
                  :_pos => (req_key + 1).to_s + ' x ' + (res_key + 1).to_s,
                  :_top_score => 0.0,
                  ((req_key + 1).to_s + ' x').to_sym => {},
                  ('x ' + (res_key + 1).to_s).to_sym => {
                    :industry => hash['skill_industry_id'].to_i,
                    :category => hash['skill_category_id'].to_i,
                    :skill => hash['skill_id'].to_i,
                    :skill_rel => hash['skill_rel_strength'].to_i, 
                    :years_exp => hash['skill_years_exp'].to_i
                  }
                }
                
                prev_search_priority = req_key
              end
            
              
              # -- 7 - UPDATE MATRIX data (sum scores AND hits)
              
              matrix_sum_scores[req_key] = [] if matrix_sum_scores[req_key].nil?
              matrix_sum_scores[req_key][res_key] = 0 if matrix_sum_scores[req_key][res_key].nil?
              # matrix_sum_scores[req_key][res_key] += value.to_i
              
              matrix_hits[req_key] = [] if matrix_hits[req_key].nil?
              matrix_hits[req_key][res_key] = 1 if value.to_i > 0
              
              # -- 8 - UPDATE '_result_data' object --> add 'pct' hit. Will be stored in the 3rd [2] index of the ':skill' entity
              
              # . SKILL --> WEIGHTED
              if req_column_id.to_s == req_column_id.to_i.to_s
                
                if matrix_scores[matrix_scores.length - 1][((req_key + 1).to_s + ' x').to_sym][req_arr[0] + '_skill'].nil? || 
                  value.to_f > matrix_scores[matrix_scores.length - 1][((req_key + 1).to_s + ' x').to_sym][:skill]
                  
                    diff = value.to_f - matrix_scores[matrix_scores.length - 1][((req_key + 1).to_s + ' x').to_sym][req_arr[0] + '_skill'].to_i.to_f
                    matrix_scores[matrix_scores.length - 1][((req_key + 1).to_s + ' x').to_sym][req_arr[0] + '_skill'] = value.to_f
                    matrix_scores[matrix_scores.length - 1][:_top_score] += diff                    
                end
                matrix_scores[matrix_scores.length - 1][((req_key + 1).to_s + ' x').to_sym][:_skills] = {} if matrix_scores[matrix_scores.length - 1][((req_key + 1).to_s + ' x').to_sym][:_skills].nil?
                matrix_scores[matrix_scores.length - 1][((req_key + 1).to_s + ' x').to_sym][:_skills][key] = value
                
                
                if value.to_i > 0 && ( _result_data[:skills][res_key][:skill][2].nil? || value.to_i > _result_data[:skills][res_key][:skill][2] )
                  
                  # Calculate a single match strength --> pct of the actual score vs the weight
                  _result_data[:skills][res_key][:skill][2] = value.to_f / match_weights[:skill][('rel_' + hash['skill_rel_strength']).to_sym].to_f
                end
                
              # . INDUSTRY, CATEGORY --> STRAIGHT score calculations, no weights included!!
              else
                
                # matrix_max_attr_scores[req_key][res_key][req_column_id.to_s.to_sym] = value.to_i
                # matrix_max_attr_scores[req_key][res_key][:_total] += value.to_i
                
                matrix_scores[matrix_scores.length - 1][((req_key + 1).to_s + ' x').to_sym][key] = value
                matrix_scores[matrix_scores.length - 1][:_top_score] += value.to_f
                
                if value.to_i > 0 && ( _result_data[:skills][res_key][req_column_id.to_sym][2].nil? || value.to_i > _result_data[:skills][res_key][req_column_id.to_sym][2] )
                  
                  # Calculate a single match strength --> pct of the actual score vs the weight
                  _result_data[:skills][res_key][req_column_id.to_sym][2] = value.to_f / match_weights[('skill_' + req_column_id.to_s).to_sym].to_f
                end
                
              end
              
              
              # Update the 'matrix_sum_scores' matrix
              matrix_sum_scores[req_key][res_key] = matrix_scores[matrix_scores.length - 1][:_top_score]
              
            end
                            
          end # COLUMN iteration
          
        end # Iterate rows
        
        
        # ---------- XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX TEMP --> Capture last element!!!
        if matrix_scores
          
          _scores_grouped = {}
          matrix_scores.each do |e|
            if _scores_grouped[e[:_pos]].nil?
              _scores_grouped[e[:_pos]] = {
                :_top_score => nil,
                :scores => []
              }                  
            end
            
            _scores_grouped[e[:_pos]][:scores] << e
            _scores_grouped[e[:_pos]][:_top_score] = e[:_top_score] if _scores_grouped[e[:_pos]][:_top_score].nil? || e[:_top_score] > _scores_grouped[e[:_pos]][:_top_score]
          end
          
          _pct = ___calculate_pct(matrix_sum_scores, match_weights)
          results[results_i][1] = {
            :_pct => [ _pct, (_pct * 100).round.to_s + '%' ],
            :_hits => matrix_hits,
            :_sum_scores => matrix_sum_scores,
            :_scores => _scores_grouped,
            :skills => _result_data[:skills]
          }
          
          # puts ' _____ ' + _pct.to_s
        end
        # ---------- XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX TEMP --> Capture last element!!!
        
        
        
        # -- BB - Extract the full results READY test --> using the 'fs2_algorithm_values' table
        
        sql = "select distinct * from fs2_algorithm_values where fs_profile_id in (#{fs_profile_ids.join(",")}) order by fs_profile_id asc;"
        algorithm_values_db = Fs2AlgorithmValue.connection.execute(sql)
        
        if algorithm_values_db
          
          # Group by 'fs_profile_id'
          _values_arr = []
          algorithm_values_db.each { |row| _values_arr << row } # -- Create an ARRAY object for easy manipulation
          _values_grouped = _values_arr.uniq.group_by {|e| e[1]} # -- Group the ARRAY by 'fs_profile_id'
          
          i = 0
          _values_grouped.each do |id, obj|
            if id == results[i][0]
              results[i][1][:skills].each_index do |skill_i|
                
                if results[i][1][:skills][skill_i].nil?
                  results[i][1][:skills][skill_i] = {
                    :industry => [ obj[skill_i][2] ],
                    :category => [ obj[skill_i][4] ],
                    :skill => [ obj[skill_i][6] ],
                    :years_exp => []
                  }
                end
                
                results[i][1][:skills][skill_i][:industry][1] = obj[skill_i][3]
                results[i][1][:skills][skill_i][:category][1] = obj[skill_i][5]
                results[i][1][:skills][skill_i][:skill][1] = obj[skill_i][7]
                results[i][1][:skills][skill_i][:years_exp][1] = obj[skill_i][9]
              end
              i += 1
            end
          end # -- Create an ARRAY object for easy manipulation
          
        end   
        
        
        # SORT
        results = results.sort {|a, b| b[1][:_pct][0] <=> a[1][:_pct][0]}
        
      end # if data[:fs_profile]
          
    end # if by[:fs_profile_id]
    
    
    # -- 11 - RETURN the results object
    
    results
    
  end
  
  def ___calculate_pct(matrix_sum_scores, match_weights)
    # --------------- PCT --------------- start
    _pct = 0
    _sum_high_scores = 0
    highest_scores_map = []
    
    # -- FIND the highest score in a ROW
    
    # ROW BY ROW 'matrix_sum_scores' scan
    matrix_sum_scores.each_index do |req_index|
      highest_scores_map[req_index] = 0 if highest_scores_map[req_index].nil?
    
      # COLUMN BY COLUMN 'matrix_sum_scores' scan  
      matrix_sum_scores[req_index].each_index do |req_second_i|
        if matrix_sum_scores[req_index][req_second_i] && highest_scores_map[req_index] < matrix_sum_scores[req_index][req_second_i]
          highest_scores_map[req_index] = matrix_sum_scores[req_index][req_second_i]
        end 
      end
      
      # SUM high-scores
      _sum_high_scores += highest_scores_map[req_index]
      
    end
    
    # PCT
    (_sum_high_scores.to_f / ( match_weights[:_max_score].to_f * highest_scores_map.length.to_f )).round(3)
    # --------------- PCT --------------- end
  end
  
  def ___generate_select_other_columns(search_data, match_weight)
    
    _select_sql = ""
    
    
    # -- X - INDUSTRY --> industry_id, _priority
    
    if search_data[:_type] == :skill_industry
      _select_sql = "if(skill_industry_id - #{search_data[:industry_id]} = 0, 1 * #{match_weight}, 0) s#{search_data[:_priority]}_industry"
    
    
    # -- X - CATEGORY --> category_id, _priority
      
    elsif search_data[:_type] == :skill_category  
      _select_sql = "if(skill_category_id - #{search_data[:category_id]} = 0, 1 * #{match_weight}, 0) s#{search_data[:_priority]}_category"
      
    
    # -- X - SKILL --> skill_id, _priority, rel_strength
    
    elsif search_data[:_type] == :skill
      _select_sql = "if(skill_id - #{search_data[:skill_id]} = 0, " + 
        ___generate_select_skills_columns(search_data[:_priority], search_data[:rel_strength]) + 
        ", 0) s#{search_data[:_priority]}_#{search_data[:skill_id]}_rel_#{search_data[:rel_strength]}"
    
    
    # -- X - YEARS EXPERIENCE --> skill_id, _priority, rel_strength
      
    elsif search_data[:_type] == :skill_years_exp
       _select_sql = "if(#{search_data[:years_exp]} >= skill_years_exp, 1 * #{match_weight}, 0) s#{search_data[:_priority]}_years_exp"
       
    end
    
    
    _select_sql
    
  end
  
  def ___generate_select_skills_columns(priority = nil, rel_strength = nil)
    return if priority.nil? || rel_strength.nil?
    
    "ROUND(((45-((ABS(#{priority} - skill_priority) + 1) * (#{priority} * skill_priority)))/5/8.8) * " + 
        "((3-((ABS(#{rel_strength} - skill_rel_strength) + 1) * .3 * (#{rel_strength} * skill_rel_strength / 2)))/.77/3.7) * 11, 1)"
  end
  
  # ------------------- CORE [17 Oct 2013] --- UP
  
  
  def _search_entities(what = [], by = {}, actions = [])
    return if by.nil? || what.nil?
    
    # -- Process
    
    # AAAAAAAAAAAAAAA
    # Left / request = Job seeker, Right / response = Job
    # - Flatten left skills -> Create a list of skills (to be used in the query)
    # - 'Category-related' -> extract list of skills with the same category
    # - [Phase 2] 'Skill-related' -> extract a more fine-grained list of related skills with weights
    # - Search the 'fs2_skills' table for the skills and related (2 columns, indicating priority)
    # - Construct the list of fs_profiles
    # - Run the match
    
    # BBBBBBBBBBBB
    # -> Skills ids
    #  + Algorithm: (1) Skills, (2) years, (3) additional parameters (undefined at this stage)
    #  + Extract category, industry and related skills -> Distinct
    #  + Search all fs_profiles / 'job_seekers' / 'published' etc based on the list of skill_ids
    #  + Iterate through all and create the points system (??) -> Prep for matching
    
    
    # ------------------------------------ Grab SKILLS DATA ------------------------------------
    
    # -- 1 - Construct the job applications (FOR DEMO purposes)
    if what.index('job_seekers') && by[:skill_ids]
      
      # !NOTE -> 'published' (below) is equal to NULL for initial testing purposes
      sql = 
        "Select" + 
          " fs_profiles.id" +
            ", fs_profile__skills.keyword_id" +
            ", fs_profile__skills.years_experience" +
            ", fs_profile__skills.priority" + 
        " From" + 
          " fs2_skills request__skills" +
          " LEFT JOIN fs2_skills_profiles fs_profiles on (fs_profiles.id = request__skills.skills_profile_id)" +
          " LEFT JOIN fs2_skills fs_profile__skills on (fs_profile__skills.skills_profile_id = fs_profiles.id)" +
        " Where" + 
          " request__skills.keyword_id IN (#{by[:skill_ids]})" +
          " AND fs_profiles.entity_type = #{ENTITY_TYPES[:job_seeker].to_s}" +
          " AND fs_profiles.profile_type = #{FS_PROFILE_TYPES[:user_profile].to_s}" +
          " AND fs_profiles.profile_status IS NULL" +
        " Order by" +
          " fs_profiles.id desc" + 
          ", fs_profile__skills.priority asc"
          
      results_from_db = nil
      
      Benchmark.bm do |x|
        # x.report("_find_by") { results_from_db = Fs2SkillsProfile.find_by_sql(sql) }
        x.report("_execute") { results_from_db = Fs2File.connection.execute(sql) }
      end
      
      
      # ------------------------------------ Prepare RESULTS ------------------------------------
      
      # Construct list of fs_profiles to grab --> Currently ALL of them
      results = []
      results_i = -1
      prev_fs_profile_id = nil
      
      results_from_db.each do |row| 
        
        # Start a new entity
        if row[0] != prev_fs_profile_id
          prev_fs_profile_id = row[0]
          results_i += 1
          
          results[results_i] = []
          results[results_i][0] = row[0]
          results[results_i][1] = {}
        end 
          
        results[results_i][1][:fs_results_match_ids_matrix] = []
        results[results_i][1][:fs_results_match_ids_matrix] << [ row[1], row[2], nil ]
        
      end
      
      # !NOTE -> 'published' (below) is equal to NULL for initial testing purposes
      sql = 
        "Select" + 
          " fs_profiles.id" +
            ", fs_profile__skills.keyword_id" +
            ", fs_profile__skills.years_experience" +
            ", fs_profile__skills.priority" + 
        " From" + 
          " fs2_skills request__skills" +
          " LEFT JOIN fs2_skills_profiles fs_profiles on (fs_profiles.id = request__skills.skills_profile_id)" +
          " LEFT JOIN fs2_skills fs_profile__skills on (fs_profile__skills.skills_profile_id = fs_profiles.id)" +
        " Where" + 
          " request__skills.keyword_id IN (#{by[:skill_ids]})" +
          " AND fs_profiles.entity_type = #{ENTITY_TYPES[:job_seeker].to_s}" +
          " AND fs_profiles.profile_type = #{FS_PROFILE_TYPES[:user_profile].to_s}" +
          " AND fs_profiles.profile_status IS NULL" +
        " Order by" +
          " fs_profiles.id desc" + 
          ", fs_profile__skills.priority asc"
          
      results_from_db = nil
      
      Benchmark.bm do |x|
        # x.report("_find_by") { results_from_db = Fs2SkillsProfile.find_by_sql(sql) }
        # x.report("_execute") { results_from_db = Fs2File.connection.execute(sql) }
      end
      
    end
    
    # -- 2 - Run the search and matching
    # TBD
  end
  
  
  def search_entities_2(data, flags)
       
    do_search_2(data, flags)
    
  end
  
  def search_entity_2(data, flags)
    
    flags[:search_single_entity] = true
    
    fs_results = do_search_2(data, flags)
    
    fs_results[0] if fs_results && fs_results[0]
    
  end  
  
  
  
  def build_baseline_sql(i_entity_type, flags = {:include_contact_details => false, :include_cv_transactions => false}, data = {})
    
    #                                                 #
    # ----------- PERFORMING SEARCH ----------- START #
    #                                                 #
    results_from_db = nil
    
    
    sql = "select "
    
    
    # --- SELECT statements for the JOB SEEKER table
    
    if i_entity_type == ENTITY_TYPES[:job_seeker]
      
      sql += 
        "js.id, js.full_name, js.anonymous js_anonymous, js.looking_for_work js_looking_for_work, " + 
        "f.id f_id, f.file_type f_ft, f.small_dimensions f_sd, f.medium_dimensions f_md, "
        
      if flags[:include_contact_details]
        sql += 
          "js_user.id js_user_id, js_user.email js_user_email, "
      end
    
    
    # --- SELECT statements for the JOB table
        
    elsif i_entity_type == ENTITY_TYPES[:job]
      
      sql += 
        "j.id, j.title j_title, " + 
        "j_comp.name j_comp_name, " + 
        "j_agen.name j_agen_name, " +
        "j_comp_f.id j_comp_logo_id, j_comp_f.file_type j_comp_logo_ft, j_comp_f.small_dimensions j_comp_logo_sd, j_comp_f.medium_dimensions j_comp_logo_md, " + 
        "j_agen_f.id j_agen_logo_id, j_agen_f.file_type j_agen_logo_ft, j_agen_f.small_dimensions j_agen_logo_sd, j_agen_f.medium_dimensions j_agen_logo_md, "
        
        if flags[:include_contact_details]
          sql += 
            "j_comp_user.id j_comp_user_id, j_comp_contact.full_name j_comp_contact_full_name, j_comp_user.email j_comp_user_email, " +
            "j_agen_user.id j_agen_user_id, j_agen_contact.full_name j_agen_contact_full_name, j_agen_user.email j_agen_user_email, "
        end
    end
    
    
    # --- SELECT statements of the SKILLS PROFILE table (including keywords)
       
    sql += 
       "sp.id sp_id, sp.updated_at sp_updated_at, sp.entity_id, sp.entity_type, sp.profile_type, " + 
       "s.keyword_id s_kid, s_k.keyword s_keyword, s.priority sp, s.years_experience, s.self_rate, " + 
       "sd.keyword_id sd_kid, sd_k.keyword sd_keyword, sd.priority sdp, " + 
       "ar.keyword_id ar_kid, ar_k.keyword ar_keyword, ar.priority arp "
       
    if flags[:include_cv_transactions] && ((i_entity_type == ENTITY_TYPES[:job_seeker] && session[:job]) || (i_entity_type == ENTITY_TYPES[:job] && session[:person]))
      sql += ", ctjt.status_id cv_trans_status_id, ctjt.updated_at cv_trans_updated_at"
    end
    
    sql += ", sp.display_matrix sp_display_matrix"
    
    sql += " from "
      
      
    # --- The SKILLS PROFILE JOIN statements
    
    if i_entity_type == ENTITY_TYPES[:job_seeker]
      
      sql += 
        "fs2_job_seekers js JOIN " +
        "fs2_skills_profiles sp on (js.id = sp.entity_id) JOIN "
        
    elsif i_entity_type == ENTITY_TYPES[:job]
      
      sql += 
        "fs2_jobs j JOIN " + 
        "fs2_skills_profiles sp on (j.id = sp.entity_id) JOIN "
        
    end
    
    
    # --- The SKILLS PROFILE - MATRIX structure (skills, skill_details and additional_requirements)
    
    sql += 
       "fs2_skills s on (sp.id = s.skills_profile_id) LEFT JOIN " + 
       "fs2_keywords s_k on (s.keyword_id = s_k.id) LEFT JOIN " + 
       "fs2_skill_details sd on (sp.id = sd.skills_profile_id) LEFT JOIN " + 
       "fs2_keywords sd_k on (sd.keyword_id = sd_k.id) LEFT JOIN " + 
       "fs2_additional_requirements ar on (sp.id = ar.skills_profile_id) LEFT JOIN " +
       "fs2_keywords ar_k on (ar.keyword_id = ar_k.id) "
    
     
    # --- Search CV transactions [JOB SEEKER] 
      
    if i_entity_type == ENTITY_TYPES[:job_seeker]
      
      sql += 
        "fs2_files f on (js.id = f.entity_id) "
        
        if flags[:include_cv_transactions] && session[:job]
          sql += "LEFT JOIN (select a.* from fs2_cvs_to_jobs_transactions a where a.job_id = " + session[:job].id.to_s + ") ctjt on (js.id = ctjt.job_seeker_id) "
        end
        
        if flags[:include_contact_details]
          
          sql +=
            "LEFT JOIN " +
            "fs2_users js_user on (js.user_id = js_user.id) "
            
        end
    
    
    # --- Search CV transactions [JOB]
      
    elsif i_entity_type == ENTITY_TYPES[:job]
      sql +=
        "fs2_organisations j_comp on (j.company_id = j_comp.id) LEFT JOIN " + 
        "fs2_files j_comp_f on (j.company_id = j_comp_f.entity_id) LEFT JOIN " + 
        "fs2_organisations j_agen on (j.agency_id = j_agen.id) LEFT JOIN " + 
        "fs2_files j_agen_f on (j.agency_id = j_agen_f.entity_id) "
        
      if flags[:include_cv_transactions]
        sql += " LEFT JOIN (select a.* from fs2_cvs_to_jobs_transactions a where a.job_seeker_id = " + session[:person].id.to_s + ") ctjt on (j.id = ctjt.job_id) "  
      end
        
      if flags[:include_contact_details]
        
        sql +=
          "LEFT JOIN " +
          "fs2_contacts j_comp_contact on (j.company_contact_id = j_comp_contact.id) LEFT JOIN " +
          "fs2_contacts j_agen_contact on (j.agency_contact_id = j_agen_contact.id) LEFT JOIN " +
          "fs2_users j_comp_user on (j_comp_contact.user_id = j_comp_user.id) LEFT JOIN " +
          "fs2_users j_agen_user on (j_agen_contact.user_id = j_agen_user.id) "
          
      end
    end
    
    sql += "where "
    
    sql
    
  end
  

  
  def do_search(request_fs_profile, where, i_entity_type, flags = {})
    
    # 1 --- Build the SQL statement
    
    sql = build_baseline_sql(i_entity_type, flags = {})
    sql += where
    sql += " order by sp.entity_id asc"
    
    
    # 2 --- Execute the search
    
    if i_entity_type == ENTITY_TYPES[:job_seeker]
      results_from_db = Fs2JobSeeker.find_by_sql(sql)
    elsif i_entity_type == ENTITY_TYPES[:job]
      results_from_db = Fs2Job.find_by_sql(sql)
    end
    
    return if results_from_db.nil?
    
    
    # 3 --- Process the search results
    
    search_entities_create_results(request_fs_profile, results_from_db, i_entity_type, flags)
    
  end
  
  
  #
  # Search single entity
  #
  def search_entity(request_fs_profile, entity_id, i_entity_type, flags = {})
    
    where = ""
    
    if i_entity_type == ENTITY_TYPES[:job_seeker] || i_entity_type == ENTITY_TYPES[:job]
      where += "sp.profile_type = " + FsBaseController::FS_PROFILE_TYPES[:user_profile].to_s +
        " and sp.entity_id = " + entity_id.to_s
      
      if i_entity_type == ENTITY_TYPES[:job_seeker]
        where += " and sp.entity_type = " + FsBaseController::ENTITY_TYPES[:job_seeker].to_s
          
      elsif i_entity_type == ENTITY_TYPES[:job]
        where += " and sp.entity_type = " + FsBaseController::ENTITY_TYPES[:job].to_s
      end
    end
    
    fs_results = do_search(request_fs_profile, where, i_entity_type, flags = {})
    
    fs_results[0] if fs_results && fs_results[0]
    
  end
  
  
  #
  # Search multiple entities
  #
  def search_entities(request_fs_profile, i_entity_type, flags = {})
       
    skill_names_ids_arr = request_fs_profile[:skill_names_ids_map].values.join(",")
    where = ""
    
    if i_entity_type == ENTITY_TYPES[:job_seeker] || i_entity_type == ENTITY_TYPES[:job]
      where += "sp.profile_type = " + FsBaseController::FS_PROFILE_TYPES[:user_profile].to_s
      
      if i_entity_type == ENTITY_TYPES[:job_seeker]
        where += " and js.id IS NOT NULL" +
          " and sp.entity_type = " + FsBaseController::ENTITY_TYPES[:job_seeker].to_s
          
      elsif i_entity_type == ENTITY_TYPES[:job]
        where = "j.id IS NOT NULL"
        " and sp.entity_type = " + FsBaseController::ENTITY_TYPES[:job].to_s
      end
    end
   
    where += 
       " AND (s.keyword_id in (" + skill_names_ids_arr + ") OR " +
       "sd.keyword_id in (" + skill_names_ids_arr + ") OR " + 
       "ar.keyword_id in (" + skill_names_ids_arr + "))"
       
    do_search(request_fs_profile, where, i_entity_type, flags = {})
    
  end
  
  def search_entities_create_results(data, flags)
    # TODO: Replace all 'local' variables with the 'data' Hash variables
    request_fs_profile = data[:request_fs_profile]
    results_from_db = data[:results_from_db]
    i_entity_type = flags[:entity_type]
    
    @results_skill_ids_matrix_map = Hash.new
    @results_skill_names_matrix_map = Hash.new
    @results_for_client = Hash.new
    
    # Set the 'iterators' - the id iterators that will flag when to skip to the next row
    previous_entity_id = nil
    previous_entity_skills_profile_id = nil
    
    results_from_db.each do |entity|
      
      # Grab the 'skills_profile_id' and the 'entity_id'
      js_skills_profile_id = entity.sp_id.to_i
      js_id = entity.entity_id.to_i
      
      # Skip iteration if this is the 2nd skills_profile onwards.
      # * Currently accepting only the latest fs_profile
      next if js_skills_profile_id != previous_entity_skills_profile_id && js_id == previous_entity_id
      
      js_skill_priority = entity.sp.to_i if !entity.sp.nil?
      js_skill_detail_priority = entity.sdp.to_i if !entity.sdp.nil?
      js_additional_requirements_priority = entity.arp.to_i if !entity.arp.nil?
      
      # If this is the 1st record OR the start of a new entity record OR the skills_profile is different
      if previous_entity_id.nil? || js_id != previous_entity_id
        
        
        # ------------- MVP V1 -------------
        
        @results_skill_ids_matrix_map[js_id] = Array.new
        @results_skill_names_matrix_map[js_id] = Array.new
        
        # 100.times do |i|
          # @results_skill_ids_matrix_map[js_id][i] = [-1, -1, nil]
          # @results_skill_names_matrix_map[js_id][i] = ["", "", Array.new(0)]
        # end
          
        
        # ------------- MVP COMPLEX -------------  
        
        # @results_skill_ids_matrix_map[js_id] = [
          # [-1, -1, nil],
          # [-1, -1, nil],
          # [-1, -1, nil],
          # [-1, -1, nil],
          # [-1, -1, nil],
          # nil, # Job type
          # nil, # Location
          # nil] # General keywords / additional requirements
        # @results_skill_names_matrix_map[js_id] = [
          # ["", "", Array.new(0)],
          # ["", "", Array.new(0)],
          # ["", "", Array.new(0)],
          # ["", "", Array.new(0)],
          # ["", "", Array.new(0)],
          # Array.new(0), # Job types
          # Array.new(0), # Locations
          # Array.new(0)] # General keywords 
        
        if @results_for_client[js_id].nil?
          
          # '@results_for_client' is used to hold information for display
          # => ':match_points', 'matched_...' fields will holds the 'text' information for display
          @results_for_client[js_id] = {
            :skills_profile_id => entity.sp_id.to_i,
            :files => Hash.new,
            :match_points => 0,
            :matched_skills => Array.new(0),
            :matched_experience_n_rate => Array.new(0),
            :matched_skill_details => Array.new(0),
            :matched_additional_requirements => Array.new(0)}
          
          # Populate the 'display_matrix' Array if it exists
          @results_for_client[js_id][:skill_display_matrix] = YAML::load(entity.sp_display_matrix) if entity.sp_display_matrix 
          
          # Populate '@results_for_client' with the 'status', 'full_name', 'email', 'update date/time'
          search_entities_populate_entity_values(js_id, entity, i_entity_type, flags)
          
        end

      end
      
      
      # --- JOB SEEKER Positions__titles
    
      if i_entity_type == ENTITY_TYPES[:job_seeker]
        populate_js_positions__titles(js_id, entity, i_entity_type)
      elsif i_entity_type == ENTITY_TYPES[:job]
        
      end
    
      
      @results_skill_ids_matrix_map[js_id][js_skill_priority - 1] = [-1, -1, nil] if @results_skill_ids_matrix_map[js_id][js_skill_priority - 1].nil?
      @results_skill_names_matrix_map[js_id][js_skill_priority - 1] = ["", "", Array.new(0)] if @results_skill_names_matrix_map[js_id][js_skill_priority - 1].nil?
        
        
      # Populate '@results_skill_ids_matrix_map' with the 'keyword_id's
      # => 'search_entities_perform_matches_pct' needs the skills_ids to perform the matching
      search_entities_populate_keyword_ids(js_id, js_skill_priority, js_skill_detail_priority, js_additional_requirements_priority, entity)
      search_entities_populate_keyword_names(js_id, js_skill_priority, js_skill_detail_priority, js_additional_requirements_priority, entity)
      
      # Populate '@results_for_client' with the relevant files
      search_entities_populate_entity_files(js_id, entity, i_entity_type)
      
      previous_entity_id = js_id
      previous_entity_skills_profile_id = js_skills_profile_id
      
    end
    
    
    search_entities_perform_matches_pct(request_fs_profile, i_entity_type)
    
    search_entities_sort_matches_pct
    
  end
  
  
  
  def populate_js_positions__titles(js_id, entity, i_entity_type)
    # Job seeker title at current or latest job (multiple)
    #TODO: Need to check if there are people without a 'current' job. They are currently dropped out of the system
    if @results_for_client[js_id][:current_positions__titles].nil?
      @results_for_client[js_id][:current_positions__titles] = [entity.js_title]
    elsif entity.js_title && @results_for_client[js_id][:current_positions__titles].index(entity.js_title).nil?
      @results_for_client[js_id][:current_positions__titles] << entity.js_title
    end
  end
  
  
  
  # Populate the following information:
  # => Status information
  # => updated date/time information
  # => full_name of the job_seeker or contact
  # => email address
  #
  def search_entities_populate_entity_values(js_id, entity, i_entity_type, flags)
    
    # Populate the 'fs_updated_at  
    @results_for_client[js_id][:sp_updated_at] = entity.sp_updated_at
    @results_for_client[js_id][:sp_updated_at_time_ago] = format_time(entity.sp_updated_at, TIME_FORMAT_TYPES[:time_ago])
      
    # Populate the 'status' information
    if flags[:include_cv_transactions]
      @results_for_client[js_id][:cv_trans_status_id] = entity['cv_trans_status_id']
      @results_for_client[js_id][:cv_trans_status_name] = Fs2CvsToJobsTransaction::get_status_name(entity['cv_trans_status_id'])
    end
    
    # Populate the 'updated_at' information
    if flags[:include_cv_transactions]
      @results_for_client[js_id][:cv_trans_updated_at] = entity['cv_trans_updated_at']
      @results_for_client[js_id][:cv_trans_updated_at_formatted] = format_time(entity['cv_trans_updated_at'])
      @results_for_client[js_id][:cv_trans_updated_at_time_ago] = format_time(entity['cv_trans_updated_at'], TIME_FORMAT_TYPES[:time_ago])
    end
      
    # Update the 'full_name' and 'email' information of the job_seeker or contacts
    if i_entity_type == ENTITY_TYPES[:job_seeker]
      
      @results_for_client[js_id][:full_name] = entity.full_name
      @results_for_client[js_id][:anonymous] = entity.js_anonymous
      @results_for_client[js_id][:looking_for_work] = entity.js_looking_for_work
      
      if flags[:include_contact_details]
        @results_for_client[js_id][:user_id] = entity.js_user_id
        @results_for_client[js_id][:user_email] = entity.js_user_email
      end
      
      
      # --- User Connector
      
      @results_for_client[js_id][:linkedin_public_profile_url] = entity.js_linkedin_url if entity.js_linkedin_url
      
    elsif i_entity_type == ENTITY_TYPES[:job]
      
      if entity.j_title
        @results_for_client[js_id][:job_title] = entity.j_title
      else
        @results_for_client[js_id][:job_title] = "-"
      end
      
      @results_for_client[js_id][:company_name] = entity.j_comp_name
      @results_for_client[js_id][:agency_name] = entity.j_agen_name
      
      if flags[:include_contact_details]
        @results_for_client[js_id][:company_contact_user_id] = entity.j_comp_user_id
        @results_for_client[js_id][:company_contact_full_name] = entity.j_comp_contact_full_name
        @results_for_client[js_id][:company_contact_user_email] = entity.j_comp_user_email
        @results_for_client[js_id][:agency_contact_user_id] = entity.j_agen_user_id
        @results_for_client[js_id][:agency_contact_full_name] = entity.j_agen_contact_full_name
        @results_for_client[js_id][:agency_contact_user_email] = entity.j_agen_user_email
      end
      
    end
  end
  
  # Populate '@results_skill_names_matrix_map' with keyword ids
  #
  def search_entities_populate_keyword_names(js_id, js_skill_priority, js_skill_detail_priority, js_additional_requirements_priority, entity)
    if !entity.sp.nil? && @results_skill_names_matrix_map[js_id][js_skill_priority - 1][0].blank?
      @results_skill_names_matrix_map[js_id][js_skill_priority - 1][0] = entity['s_keyword'].to_s
      @results_skill_names_matrix_map[js_id][js_skill_priority - 1][1] = entity.years_experience.to_i
    end
    
    if !entity.sp.nil? && !@results_skill_names_matrix_map[js_id][js_skill_priority - 1][2]
      @results_skill_names_matrix_map[js_id][js_skill_priority - 1][2] = Array.new()
    end
    
    # ASSUMPTION: Duplicates are consistent, don't need to check if a value already exists, just override
    if !entity.sd_kid.nil? && !entity.sdp.nil? && !js_skill_detail_priority.nil?
      @results_skill_names_matrix_map[js_id][js_skill_priority - 1][2][js_skill_detail_priority - 1] = entity['sd_keyword'].to_s
    end
    
    # ASSUMPTION: Duplicates are consistent, don't need to check if a value already exists, just override
    if !entity.ar_kid.nil? && !entity.arp.nil? && !js_additional_requirements_priority.nil?
      @results_skill_names_matrix_map[js_id][7][js_additional_requirements_priority - 1] = entity['ar_keyword'].to_s
    end
  end  
  
  # Populate '@results_skill_ids_matrix_map' with keyword ids
  #
  def search_entities_populate_keyword_ids(js_id, js_skill_priority, js_skill_detail_priority, js_additional_requirements_priority, entity)
    # puts " YYYY: " + js_id.to_s + " ; " + js_skill_priority.to_s + " ; " + js_skill_detail_priority.to_s + " ; " + js_additional_requirements_priority.to_s + " ; " + @results_skill_ids_matrix_map[js_id][js_skill_priority - 1].to_s
    
    if !entity.sp.nil? && @results_skill_ids_matrix_map[js_id][js_skill_priority - 1][0] == -1 
      @results_skill_ids_matrix_map[js_id][js_skill_priority - 1][0] = entity.s_kid.to_i
      @results_skill_ids_matrix_map[js_id][js_skill_priority - 1][1] = entity.years_experience.to_i
    end
    
    if !entity.sp.nil? && !@results_skill_ids_matrix_map[js_id][js_skill_priority - 1][2]
      @results_skill_ids_matrix_map[js_id][js_skill_priority - 1][2] = Array.new()
    end
    
    # ASSUMPTION: Duplicates are consistent, don't need to check if a value already exists, just override
    if !entity.sd_kid.nil? && !entity.sdp.nil? && !js_skill_detail_priority.nil?
      @results_skill_ids_matrix_map[js_id][js_skill_priority - 1][2][js_skill_detail_priority - 1] = entity.sd_kid.to_i
    end
    
    if !@results_skill_ids_matrix_map[js_id][7] 
      @results_skill_ids_matrix_map[js_id][7] = Array.new(0)
    end
    
    # ASSUMPTION: Duplicates are consistent, don't need to check if a value already exists, just override
    if !entity.ar_kid.nil? && !entity.arp.nil? && !js_additional_requirements_priority.nil?
      @results_skill_ids_matrix_map[js_id][7][js_additional_requirements_priority - 1] = entity.ar_kid.to_i
    end
  end
  
  def search_entities_populate_entity_files(js_id, entity, i_entity_type)
    #                                     #
    # ----------- FILES ----------- START #
    #                                     #
    if i_entity_type == ENTITY_TYPES[:job_seeker]
      
      if entity.js_anonymous.to_i == 1
        
        @results_for_client[js_id][:files][Fs2File::FILE_TYPES.index(entity.f_ft.to_i)] = 
          {:id => session[:defaults][:anonymous_profile_photo_file].id, 
          :small_dimensions => session[:defaults][:anonymous_profile_photo_file].small_dimensions,
          :medium_dimensions => session[:defaults][:anonymous_profile_photo_file].medium_dimensions}
        
      elsif !entity.f_id.nil?
        
        @results_for_client[js_id][:files][Fs2File::FILE_TYPES.index(entity.f_ft.to_i)] = 
          {:id => entity.f_id, 
          :small_dimensions => entity.f_sd,
          :medium_dimensions => entity.f_md}
          
      end
      
    elsif i_entity_type == ENTITY_TYPES[:job]
      
      if !entity.j_comp_logo_id.nil?
        @results_for_client[js_id][:files][Fs2File::FILE_TYPES.index(entity.j_comp_logo_ft.to_i)] = 
          {:id => entity.j_comp_logo_id, 
          :small_dimensions => entity.j_comp_logo_sd,
          :medium_dimensions => entity.j_comp_logo_md}
      end
      
      if !entity.j_agen_logo_id.nil?
        @results_for_client[js_id][:files][Fs2File::FILE_TYPES.index(entity.j_agen_logo_ft.to_i)] = 
          {:id => entity.j_agen_logo_id, 
          :small_dimensions => entity.j_agen_logo_sd,
          :medium_dimensions => entity.j_agen_logo_md}
      end
      
    end
    #                                   #
    # ----------- FILES ----------- END #
    #   
  end
  
  def search_entities_perform_matches_pct(request_fs_profile, i_entity_type)
    # Define the basline direction (for matching minimum years experience criteria)
    baseline = 0 # left side = search = is baseline
    
    case i_entity_type
      when ENTITY_TYPES[:job_seeker] # Searching for job seekers, '0' is the baseline (the job requirements) = left hand-side
        baseline = 0
      when ENTITY_TYPES[:job] # Searching for jobs, the 'job' is the baseline, i.e. 1 = right hand-side
        baseline = 1
    end
    
    # Hash holding the match objects
    matches_h = {}
    
    @results_skill_ids_matrix_map.each do |entity_id, skill_ids_matrix|

      # 'skill_ids_matrix' has the 'details' object. This object is a Hash where 'key -> Priority, value -> keyword id'      
      # matches_h[entity_id] = Fs2Match.new(request_fs_profile[:skill_ids_matrix], skill_ids_matrix, baseline)
      # matches_h[entity_id].match
      
      matches_h[entity_id] = Fs2Match2.new(request_fs_profile[:skill_ids_matrix], skill_ids_matrix, baseline)
      matches_h[entity_id].match
      
      @results_for_client[entity_id][:fs_result_match_ids_matrix] = matches_h[entity_id].result_matrix
      @results_for_client[entity_id][:fs_result_match_names_matrix] = @results_skill_names_matrix_map[entity_id]
      @results_for_client[entity_id][:fs_search_match_ids_matrix] = matches_h[entity_id].search_matrix
      @results_for_client[entity_id][:match_pct] = matches_h[entity_id].pct
      
      # Update the 'results' object
      # if @results_for_client[entity_id][:skill_display_matrix].nil?
#         
        # case i_entity_type
          # when ENTITY_TYPES[:job_seeker] # Searching for job seekers, '0' is the baseline (the job requirements) = left hand-side
            # prep_skills_profile({:job_seeker_id => entity_id})
          # when ENTITY_TYPES[:job] # Searching for jobs, the 'job' is the baseline, i.e. 1 = right hand-side
            # prep_skills_profile({:job_id => entity_id})
        # end
#         
        # @results_for_client[entity_id][:skill_display_matrix] = []
#         
        # 5.times do |row|
          # @results_for_client[entity_id][:skill_display_matrix][row] = Array.new
          # @results_for_client[entity_id][:skill_display_matrix][row][0] = request_fs_profile[:skill_names_matrix][row][0]
          # @results_for_client[entity_id][:skill_display_matrix][row][1] = request_fs_profile[:skill_names_matrix][row][1]
          # @results_for_client[entity_id][:skill_display_matrix][row][2] = request_fs_profile[:skill_names_matrix][row][2]
        # end
#         
        # # Add the 'result_matrix' to the DB
        # fs_profile = Fs2SkillsProfile.find_by_id(@results_for_client[entity_id][:skills_profile_id])        
        # fs_profile.update_attributes({:display_matrix => @results_for_client[entity_id][:skill_display_matrix]}) if fs_profile
#         
      # end
            
      puts " XXXX MATCH: " + entity_id.to_s + "[" + i_entity_type.to_s + "] ; " + matches_h[entity_id].pct.to_s
            
    end
    
    puts "STOP"
  end
  
  def search_entities_sort_matches_pct
    # 7) Sort the search results by the 'matched_points' descending
    # *********************************************************************************
    @results_for_client.sort {|a, b| b[1][:match_pct] <=> a[1][:match_pct]}
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
      @js_skills_matrix_search.each do |js_id, response|
      
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
        
        if @js_skills_matrix_search[:additional_requirements]
          @js_skills_matrix_search[:additional_requirements].each do |additional_req_priority, additional_req_keyword_id|
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
        
      end # '@js_skills_matrix_search' iteration (iterate over all 'job seekers')
      
    end # '@keywords_hash' iteration (iterate over all 'keywords')
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
  
end
