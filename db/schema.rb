# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of Active Record to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20180518000000) do

  create_table "activities", :force => true do |t|
    t.string   "controller"
    t.string   "action"
    t.string   "parameter_ids"
    t.string   "parameter_values"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "parameter_names"
    t.integer  "person_id"
  end

  create_table "custom_types", :force => true do |t|
    t.integer  "type_id"
    t.integer  "user_id"
    t.integer  "select_id"
    t.string   "select_value"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "email_confirmations", :force => true do |t|
    t.integer  "person_id"
    t.string   "confirmation_string"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "email_users", :force => true do |t|
    t.string   "email"
    t.string   "phone"
    t.integer  "status"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "enumerations", :force => true do |t|
    t.enum "severity", :limit => [:low, :medium, :high, :critical]
    t.enum "color",    :limit => [:red, :blue, :green, :yellow]
  end

  create_table "feedbacks", :force => true do |t|
    t.string   "controller"
    t.string   "action"
    t.integer  "my_mailer_metadata_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "flyc_files", :force => true do |t|
    t.string   "name"
    t.string   "mime_type"
    t.string   "extension"
    t.integer  "size"
    t.string   "path"
    t.string   "uri"
    t.integer  "person_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "fs2_additional_requirements", :force => true do |t|
    t.integer  "skills_profile_id"
    t.integer  "priority"
    t.integer  "keyword_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "fs2_algorithm_handles", :force => true do |t|
    t.integer "fs_profile_id"
    t.integer "skill_industry_id"
    t.integer "skill_category_id"
    t.integer "skill_id"
    t.integer "skill_rel_strength"
    t.integer "skill_years_exp"
    t.integer "skill_priority"
  end

  create_table "fs2_algorithm_values", :force => true do |t|
    t.integer "fs_profile_id"
    t.integer "skill_industry_id"
    t.string  "skill_industry_name"
    t.integer "skill_category_id"
    t.string  "skill_category_name"
    t.integer "skill_id"
    t.string  "skill_name"
    t.integer "skill_years_exp"
    t.integer "skill_priority"
  end

  create_table "fs2_algorithm_weights", :force => true do |t|
    t.integer "skill_industry_id"
    t.integer "skill_category_id"
    t.integer "skill_id"
    t.integer "skill_rel_strength"
    t.integer "skill_years_exp"
    t.integer "skill_priority"
  end

  create_table "fs2_anonymous_companies", :force => true do |t|
    t.integer  "real_company_id"
    t.string   "linkedin_company_name"
    t.integer  "linkedin_company_id"
    t.integer  "type_id"
    t.integer  "size_id"
    t.integer  "market_id"
    t.integer  "industry_id"
    t.string   "address_region"
    t.string   "address_city"
    t.string   "address_country"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "fs2_contacts", :force => true do |t|
    t.string   "full_name"
    t.string   "mobile_phone"
    t.string   "work_phone"
    t.string   "other_phone"
    t.integer  "contact_type"
    t.integer  "organisation_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "user_id"
    t.string   "organisation_role"
  end

  create_table "fs2_cv_educations", :force => true do |t|
    t.integer  "cv_id"
    t.string   "degree"
    t.string   "field"
    t.integer  "anonymous_education_institute_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "fs2_cv_positions", :force => true do |t|
    t.integer  "cv_id"
    t.string   "domain"
    t.integer  "anonymous_company_id"
    t.integer  "start_month"
    t.integer  "start_year"
    t.integer  "end_month"
    t.integer  "end_year"
    t.boolean  "is_current"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "title"
    t.integer  "linkedin_position_id"
  end

  create_table "fs2_cvs", :force => true do |t|
    t.integer  "job_seeker_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "fs2_cvs_to_jobs_transactions", :force => true do |t|
    t.integer  "job_seeker_id"
    t.integer  "job_id"
    t.integer  "status_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "fs2_education_institutes", :force => true do |t|
    t.string   "linkedin_education_institute_name"
    t.string   "address_city"
    t.string   "address_country"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "fs2_files", :force => true do |t|
    t.string   "name"
    t.string   "mime_type"
    t.string   "extension"
    t.integer  "size"
    t.string   "path"
    t.integer  "entity_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "file_type"
    t.string   "original_dimensions"
    t.string   "small_dimensions"
    t.string   "medium_dimensions"
    t.string   "large_dimensions"
    t.integer  "entity_type_id"
  end

  create_table "fs2_industries", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "fs2_job_applications", :force => true do |t|
    t.integer  "job_seeker_fs_profile_id"
    t.integer  "job_fs_profile_id"
    t.integer  "status_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "fs2_job_publishing_post_visitors", :force => true do |t|
    t.integer  "job_publishing_post_id"
    t.integer  "visitor_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "fs2_job_publishing_posts", :force => true do |t|
    t.integer  "user_id"
    t.integer  "job_id"
    t.integer  "publishing_channel_id"
    t.string   "post_type"
    t.string   "status"
    t.string   "title"
    t.text     "summary"
    t.string   "content_submitted_url"
    t.string   "content_submitted_image_url"
    t.string   "content_title"
    t.text     "content_description"
    t.string   "ref_key"
    t.string   "api_response_code"
    t.text     "api_response_body"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "post_key"
    t.string   "api_response_message"
  end

  create_table "fs2_job_seekers", :force => true do |t|
    t.string   "full_name"
    t.boolean  "anonymous"
    t.boolean  "looking_for_work"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "profile_photo_id"
    t.integer  "user_id"
    t.string   "full_name_secret"
    t.integer  "profile_photo_id_secret"
    t.string   "phone_number_1"
  end

  create_table "fs2_jobs", :force => true do |t|
    t.string   "title"
    t.text     "description"
    t.string   "responsibilities"
    t.integer  "company_id"
    t.integer  "company_contact_id"
    t.integer  "agency_id"
    t.integer  "agency_contact_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "teaser"
    t.string   "location"
    t.integer  "status_id"
  end

  create_table "fs2_keyword_blocks", :force => true do |t|
    t.integer "keyword_id"
    t.boolean "blocked"
    t.integer "readon_id"
    t.integer "replace_id"
  end

  create_table "fs2_keywords", :force => true do |t|
    t.string  "keyword"
    t.integer "replace_with_skill_id"
  end

  create_table "fs2_mailer_actions", :force => true do |t|
    t.integer "user_id"
    t.string  "controller"
    t.string  "action"
    t.string  "parameter_ids"
    t.string  "parameter_names"
    t.string  "parameter_values"
    t.string  "email_action_key"
  end

  create_table "fs2_mailer_emails", :force => true do |t|
    t.text     "headers"
    t.text     "body_attributes"
    t.string   "template"
    t.integer  "priority"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "fs2_map_category_to_industry", :force => true do |t|
    t.integer "category_id"
    t.integer "industry_id"
  end

  create_table "fs2_map_skill_to_category", :force => true do |t|
    t.integer "skill_id"
    t.integer "skill_category_id"
  end

  create_table "fs2_map_skill_to_publishing_channels", :force => true do |t|
    t.integer  "industry_id"
    t.integer  "category_id"
    t.integer  "skill_id"
    t.integer  "publishing_channel_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "fs2_map_user_to_publishing_channels", :force => true do |t|
    t.integer  "user_id"
    t.integer  "publishing_channel_id"
    t.string   "channel_status"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "fs2_organisations", :force => true do |t|
    t.string   "name"
    t.string   "slogan"
    t.string   "blurb"
    t.integer  "phone"
    t.string   "email"
    t.string   "website"
    t.integer  "organisation_type"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "fs2_publishing_channels", :force => true do |t|
    t.string   "platform"
    t.string   "channel_type"
    t.string   "channel_id"
    t.string   "moderated_content_types"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "channel_name"
    t.text     "short_description"
    t.string   "website_url"
    t.string   "site_group_url"
    t.string   "small_logo_url"
    t.string   "large_logo_url"
    t.integer  "num_members"
  end

  create_table "fs2_skill_categories", :force => true do |t|
    t.string "category_name"
  end

  create_table "fs2_skill_details", :force => true do |t|
    t.integer  "skill_id"
    t.integer  "skills_profile_id"
    t.integer  "priority"
    t.integer  "keyword_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "fs2_skill_keywords", :force => true do |t|
    t.string  "en_US"
    t.boolean "suggest_as_primary"
    t.integer "type_id"
  end

  create_table "fs2_skills", :force => true do |t|
    t.integer  "skills_profile_id"
    t.integer  "priority"
    t.integer  "keyword_id"
    t.integer  "years_experience"
    t.integer  "self_rate"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "fs2_skills_counters", :force => true do |t|
    t.integer "keyword_id"
    t.integer "total"
    t.integer "as_primary"
    t.integer "as_primary_skill_1"
    t.integer "as_primary_skill_2"
    t.integer "as_primary_skill_3"
    t.integer "as_primary_skill_4"
    t.integer "as_primary_skill_5"
    t.integer "as_secondary_skill_1"
    t.integer "as_secondary_skill_2"
    t.integer "as_secondary_skill_3"
    t.integer "as_secondary_skill_4"
    t.integer "as_secondary_skill_5"
  end

  create_table "fs2_skills_profiles", :force => true do |t|
    t.integer  "entity_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "display_matrix"
    t.text     "label"
    t.integer  "entity_type"
    t.integer  "profile_type"
    t.integer  "profile_status"
  end

  create_table "fs2_skills_profiles_matches", :force => true do |t|
    t.integer  "js_id"
    t.integer  "js_skills_profile_id"
    t.integer  "js_match_status"
    t.integer  "j_id"
    t.integer  "j_skills_profile_id"
    t.integer  "j_match_status"
    t.datetime "match_date"
    t.integer  "match_points"
    t.string   "match_skills"
    t.string   "match_skills_details"
    t.string   "match_additional_requirements"
  end

  create_table "fs2_skills_profiles_summaries", :force => true do |t|
    t.integer "js_id"
    t.integer "js_skills_profile_id"
    t.integer "js_match_points"
    t.string  "js_match_skills"
    t.string  "js_match_skills_details"
    t.string  "js_match_additional_requirements"
  end

  create_table "fs2_skills_related", :force => true do |t|
    t.integer "skill_id"
    t.integer "related_skill_id"
    t.integer "related_strength"
  end

  create_table "fs2_suggested_related_primary_skills", :force => true do |t|
    t.integer "primary_skill_id"
    t.integer "related_primary_skill_id"
  end

  create_table "fs2_suggested_sub_skills", :force => true do |t|
    t.integer "primary_skill_id"
    t.integer "sub_skill_id"
  end

  create_table "fs2_templates", :force => true do |t|
    t.string  "name"
    t.integer "skills_profile_id"
  end

  create_table "fs2_user_connectors", :force => true do |t|
    t.integer  "user_id"
    t.string   "linkedin_access_token"
    t.string   "linkedin_access_secret"
    t.string   "linkedin_id"
    t.string   "linkedin_first_name"
    t.string   "linkedin_last_name"
    t.string   "linkedin_public_profile_url"
    t.string   "linkedin_email"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "status_id"
  end

  create_table "fs2_user_marketing_funnels", :force => true do |t|
    t.integer  "user_id"
    t.integer  "marketing_funnel_id"
    t.integer  "state_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "fs2_user_network_connections", :force => true do |t|
    t.integer "user_connector_id"
    t.string  "friend_linkedin_id"
    t.integer "friend_connector_id"
  end

  create_table "fs2_user_notifications", :force => true do |t|
    t.integer  "user_id"
    t.string   "entity_name"
    t.datetime "seen_datetime"
    t.datetime "emailed_datetime"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "fs2_users", :force => true do |t|
    t.string   "email"
    t.string   "password"
    t.string   "salt"
    t.string   "hashed_password"
    t.string   "remember_token"
    t.datetime "remember_token_expires"
    t.integer  "status_id"
    t.integer  "user_type_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "referral_id"
  end

  create_table "fs2_users_realtime", :force => true do |t|
    t.integer  "user_id"
    t.boolean  "is_online"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "fs2_visitors", :force => true do |t|
    t.string   "user_id"
    t.string   "ip"
    t.string   "referrer"
    t.string   "agent"
    t.integer  "funnel_id"
    t.integer  "funnel_step"
    t.boolean  "new_visitor"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "fs_hiring_managers", :force => true do |t|
    t.string   "full_name"
    t.string   "employer_name"
    t.string   "employer_location"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "fs_job_seeker_single_skills", :force => true do |t|
    t.integer  "priority"
    t.string   "name"
    t.integer  "years_experience"
    t.integer  "self_rate"
    t.string   "details"
    t.string   "digest"
    t.integer  "fs_job_seeker_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "fs_job_seekers", :force => true do |t|
    t.string   "full_name"
    t.boolean  "anonymous"
    t.integer  "looking_for_work"
    t.string   "additional_requirements"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "digest"
  end

  create_table "fs_job_single_skills", :force => true do |t|
    t.integer  "priority"
    t.string   "name"
    t.integer  "years_experience"
    t.integer  "self_rate"
    t.string   "details"
    t.string   "digest"
    t.integer  "fs_job_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "fs_jobs", :force => true do |t|
    t.boolean  "published"
    t.boolean  "visible"
    t.string   "additional_requirements"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "fs_recruitment_agents", :force => true do |t|
    t.string   "full_name"
    t.string   "recruitment_agency_name"
    t.string   "recruitment_agency_location"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "fs_template_single_skills", :force => true do |t|
    t.integer  "priority"
    t.string   "name"
    t.integer  "years_experience"
    t.integer  "self_rate"
    t.string   "details"
    t.string   "digest"
    t.integer  "fs_template_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "fs_templates", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "ip_to_countries", :force => true do |t|
    t.float    "ip_from"
    t.float    "ip_to"
    t.string   "registry"
    t.integer  "assigned"
    t.string   "ctry"
    t.string   "cntry"
    t.string   "country"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "messages", :force => true do |t|
    t.string   "subject"
    t.string   "person_name"
    t.string   "recipients"
    t.string   "sender"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "confirmation_email_key"
    t.string   "person_password"
  end

  create_table "my_mailer_actions", :force => true do |t|
    t.integer  "my_mailer_metadata_id"
    t.string   "controller"
    t.string   "action"
    t.string   "parameter_ids"
    t.string   "parameter_names"
    t.string   "parameter_values"
    t.string   "email_action_key"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "my_mailer_emails", :force => true do |t|
    t.integer  "my_mailer_metadata_id"
    t.string   "headers"
    t.string   "body_attributes"
    t.string   "template"
    t.integer  "priority"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "my_mailer_messages", :force => true do |t|
    t.integer "my_mailer_metadata_id"
    t.string  "message_html",          :limit => 10000
  end

  create_table "my_mailer_metadatas", :force => true do |t|
    t.integer  "sender_id"
    t.string   "subject"
    t.string   "message_summary"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "message_status_id"
    t.integer  "parent_message_id"
    t.integer  "message_type_id"
  end

  create_table "my_mailer_recipients", :force => true do |t|
    t.integer "my_mailer_metadata_id"
    t.integer "recipient_id"
    t.integer "message_status_id"
  end

  create_table "notes", :force => true do |t|
    t.string   "note_contents"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "role_application_id"
  end

  create_table "organisations", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "type_id"
    t.string   "phone"
    t.string   "fax"
    t.string   "website"
    t.string   "email"
    t.integer  "status_id"
  end

  create_table "people", :force => true do |t|
    t.string   "first_name"
    t.string   "last_name"
    t.string   "password"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "primary_email"
    t.integer  "person_type_id"
    t.string   "phone_home"
    t.string   "phone_work"
    t.string   "fax"
    t.string   "mobile"
    t.string   "website"
    t.integer  "organisation_id"
    t.integer  "status_id"
    t.string   "remember_token"
    t.datetime "remember_token_expires"
    t.string   "salt"
    t.string   "hashed_password"
    t.string   "organisation_role"
    t.string   "bookmarklet_session_token"
  end

  create_table "person_to_organisations", :force => true do |t|
    t.integer  "person_id"
    t.integer  "organisation_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "photos", :force => true do |t|
    t.string "description"
    t.string "content_type"
    t.string "filename"
    t.binary "binary_data"
  end

  create_table "role_applications", :force => true do |t|
    t.integer  "person_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "role_id"
    t.integer  "status_id"
  end

  create_table "roles", :force => true do |t|
    t.string   "title"
    t.string   "description",         :limit => 10000
    t.string   "reference"
    t.date     "close_date"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.float    "salary_min"
    t.float    "salary_max"
    t.integer  "agency_id"
    t.integer  "company_id"
    t.integer  "agent_id"
    t.integer  "source_id"
    t.integer  "type_id"
    t.integer  "company_contact_id"
    t.integer  "salary_frequency_id"
    t.integer  "duration"
    t.integer  "duration_type_id"
    t.integer  "location_id"
    t.date     "start_date"
    t.string   "external_link"
  end

  create_table "salary_frequencies", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "test_capistrano", :force => true do |t|
    t.string   "subject"
    t.string   "person_name"
    t.string   "recipients"
    t.string   "sender"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "website_parsing_fields", :force => true do |t|
    t.integer "website_parsing_page_id"
    t.string  "jquery_css_selector"
    t.integer "field_type"
  end

  create_table "website_parsing_pages", :force => true do |t|
    t.integer "organisation_id"
    t.string  "uri_string"
    t.integer "page_type"
  end

end
