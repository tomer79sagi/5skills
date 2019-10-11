
ActionController::Routing::Routes.draw do |map|
  

#
# Mapping of 'Role Application Controller'
#
  map.with_options(:controller => 'to_email') do |to_email|
    
    to_email.sms_reciever 'sms_reciever', :action => 'sms_reciever'
   
  end
  
 
#
# Mapping of 'Role Application Controller'
#
  map.with_options(:controller => 'role_applications') do |applications|
    applications.view_applications 'applications', :action => 'view_applications'
    
    applications.new_job 'application/new', :action => 'new_job'
    applications.save_application 'application/save', :action => 'save_application'
    
    applications.create_application_quick 'application/create/quick', :action => 'create_application_quick'
    
    applications.edit_application_agency 'application/:application_id/edit/agency', :action => 'edit_application_agency'
    applications.view_application_agency 'application/:application_id/view/agency', :action => 'view_application_agency'
    applications.update_application_agency 'application/:application_id/update/agency', :action => 'update_application_agency'
    
    applications.edit_application_company 'application/:application_id/edit/company', :action => 'edit_application_company'
    applications.view_application_company 'application/:application_id/view/company', :action => 'view_application_company'
    applications.update_application_company 'application/:application_id/update/company', :action => 'update_application_company'
    
#    applications.edit_application_messages 'application/:application_id/edit/messages', :action => 'edit_application_messages'
#    applications.edit_application_notifications 'application/:application_id/edit/notifications', :action => 'edit_application_notifications'
    
    applications.edit_application 'application/:application_id/edit', :action => 'edit_application'
    applications.view_application 'application/:application_id/view', :action => 'view_application'
    
    applications.update_application 'application/:application_id/update', :action => 'update_application'
    applications.delete_job 'application/:application_id/delete', :action => 'delete_job'
    
    applications.edit_application_status 'application/:application_id/edit/status', :action => 'edit_application_status'
    applications.update_application_status 'application/:application_id/update/status', :action => 'update_application_status'
    
  end
  
#
# Mapping of 'People Controller'
# 
  map.with_options(:controller => 'application_notes') do |notes|
    
    notes.view_application_notes 'application/:application_id/notes/view', :action => 'view_application_notes'
    notes.create_application_note_quick 'application/:application_id/notes/create/quick', :action => 'create_application_note_quick'
    
    notes.view_application_note 'note/:note_id/view', :action => 'view_application_note'
    notes.edit_application_note 'note/:note_id/edit', :action => 'edit_application_note'
    notes.new_application_note 'application/:application_id/new/note', :action => 'new_application_note'
    notes.save_application_note 'application/:application_id/note/save', :action => 'save_application_note'
    notes.update_application_note 'note/:note_id/update', :action => 'update_application_note'
    notes.create_application_note 'application/:application_id/create/note', :action => 'create_application_note'
    notes.delete_application_note 'note/:note_id/delete', :action => 'delete_application_note'
    
  end
  
  map.with_options(:controller => 'contacts') do |contacts|
    
    contacts.delete_contact '/contact/:contact_id/delete', :action => 'delete_contact'
    contacts.edit_contact 'contact/:contact_id/edit', :action => 'edit_contact'
    contacts.update_contact 'contact/:contact_id/update', :action => 'update_contact'
    
    contacts.view_organisation_contacts 'organisation/:organisation_id/contacts/:contact_id', :action => 'view_organisation_contacts'
    contacts.view_organisation_contacts 'organisation/:organisation_id/contacts', :action => 'view_organisation_contacts'
    contacts.new_organisation_contact 'organisation/:organisation_id/contact/new', :action => 'new_organisation_contact'
    contacts.save_organisation_contact 'organisation/:organisation_id/contact/save', :action => 'save_organisation_contact'
    
    ## View all contacts (not implemented yet)
#    contacts.view_contacts 'contacts/view', :action => 'view_contacts'
    
  end
  
  map.with_options(:controller => 'organisations') do |organisations|
    
    organisations.view_organisations 'organisations', :action => 'view_organisations'
    organisations.create_organisation_quick 'organisation/create/quick', :action => 'create_organisation_quick'
    
    organisations.view_organisation 'organisation/:organisation_id/view', :action => 'view_organisation'
    organisations.edit_organisation 'organisation/:organisation_id/edit', :action => 'edit_organisation'
    organisations.update_organisation 'organisation/:organisation_id/update', :action => 'update_organisation'
    organisations.new_organisation 'organisation/new', :action => 'new_organisation'
    organisations.save_organisation 'organisation/save', :action => 'save_organisation'
    organisations.delete_organisation 'organisation/:organisation_id/delete', :action => 'delete_organisation'
    
  end
  
  map.with_options(:controller => 'companies') do |companies|
    
    companies.view_companies 'companies', :action => 'view_organisations'
    companies.create_company_quick 'company/create/quick', :action => 'create_organisation_quick'
    
    companies.new_company 'company/new', :action => 'new_organisation'
    companies.save_company 'company/save', :action => 'save_organisation'  
    
#    companies.view_company 'company/:company_id/view', :action => 'view_organisation'
#    companies.edit_company 'company/:company_id/edit', :action => 'edit_organisation'
#    companies.update_company 'company/:company_id/update', :action => 'update_organisation'
#    companies.delete_company 'company/:company_id/delete', :action => 'delete_organisation'
    
  end
  
  map.with_options(:controller => 'agencies') do |agencies|
    
    agencies.view_agencies 'agencies', :action => 'view_organisations'
    agencies.create_agency_quick 'agency/create/quick', :action => 'create_organisation_quick'
    
    agencies.new_agency 'agency/new', :action => 'new_organisation'
    agencies.save_agency 'agency/save', :action => 'save_organisation'
    
#    agencies.view_agency 'agency/:agency_id/view', :action => 'view_organisation'
#    agencies.edit_agency 'agency/:agency_id/edit', :action => 'edit_organisation'
#    agencies.update_agency 'agency/:agency_id/update', :action => 'update_organisation'
#    agencies.delete_agency 'agency/:agency_id/delete', :action => 'delete_organisation'
    
  end
     
#
# Mapping of 'People Controller'
# 
#  map.with_options(:controller => 'people') do |people|
#    people.view_candidates 'candidates', :action => 'view_candidates'
#    people.show_candidate 'candidate/:candidate_id/show', :action => 'show_candidate'
#    people.add_candidate 'candidate/add', :action => 'add_candidate'
#    people.create_candidate 'candidate/create', :action => 'create_candidate'
#    people.edit_candidate 'candidate/:candidate_id/edit', :action => 'edit_candidate'
#    people.update_candidate 'candidate/:candidate_id/update', :action => 'update_candidate'
#    people.remove_candidate 'candidate/:candidate_id/remove', :action => 'remove_candidate'
#  end
  
#  map.with_options(:controller => 'messages') do |messages|
#    messages.view_inbox_message 'messages/inbox/:message_id/view', :action => 'view_inbox_message'
#    messages.view_sent_message 'messages/sent/:message_id/view', :action => 'view_sent_message'
#    
#    messages.view_inbox_messages 'messages/inbox', :action => 'view_inbox_messages'
#    messages.view_sent_messages 'messages/sent', :action => 'view_sent_messages'
#  end
  
  map.with_options(:controller => 'user_messages') do |messages|
    messages.view_inbox_messages 'messages/inbox', :action => 'view_inbox_messages'
    messages.view_sent_messages 'messages/sent', :action => 'view_sent_messages'
    
    messages.view_inbox_message 'messages/inbox/:message_id/view', :action => 'view_inbox_message'
    messages.view_sent_message 'messages/sent/:message_id/view', :action => 'view_sent_message'
    
    messages.reply_to_message 'messages/inbox/:message_id/reply', :action => 'reply_to_message'
    messages.send_reply_to_message 'messages/inbox/:message_id/reply/send', :action => 'send_reply_to_message'
  end
  
  #
# Mapping of
#
  map.with_options(:controller => 'my_mailer') do |email|
    email.email_confirm 'person/:person_id/confirmation_email', :action => 'email_confirm'
    email.email_registration_confirmed 'person/:person_id/email_registration_confirmed', :action => 'email_registration_confirmed'
    email.email_forgot_password 'person/:person_id/forgot_password', :action => 'email_forgot_password'
    
    email.send_contact_us_message 'contact_us/send', :action => 'send_contact_us_message'
    email.send_message 'message/send', :action => 'send_message'
    
    email.email_action_key 'redirect/:email_action_key', :action => 'process_email_action_key'
  end
  
  map.with_options(:controller => 'general') do |general|
    general.contact_us 'contact_us', :action => 'contact_us'
    general.send_contact_us 'send_contact_us', :action => 'send_contact_us'
    
    general.about_us 'about_us', :action => 'about_us'
    general.iframe_test 'general/iframe_test', :action => 'iframe_test'
  end
  
  map.with_options(:controller => 'general_application') do |general_app|
    general_app.activities 'activities', :action => 'activities'
    # general_app.mechanize 'mechanize', :action => 'mechanize'
    
    general_app.provide_feedback 'provide_feedback', :action => 'provide_feedback'
    general_app.send_feedback 'send_feedback', :action => 'send_feedback'
  end
  
  map.with_options(:controller => 'fs_mvp') do |fs_mvp_app|
    # fs_mvp_app.home '', :action => 'mvp_s_job_seeker_EN'
    fs_mvp_app.mvp_test 'test', :action => 'mvp_s_test'
    
    fs_mvp_app.mvp_job_seeker 'job_seeker', :action => 'mvp_s_job_seeker_EN'
    fs_mvp_app.mvp_recruiter 'recruiter', :action => 'mvp_s_recruiter_EN'
    fs_mvp_app.mvp_job_seeker_HE 'job_seeker/he', :action => 'mvp_s_job_seeker_HE'
    fs_mvp_app.mvp_recruiter_HE 'recruiter/he', :action => 'mvp_s_recruiter_HE'
    fs_mvp_app.mvp_job_seeker_EN 'job_seeker/en', :action => 'mvp_s_job_seeker_EN'
    fs_mvp_app.mvp_recruiter_EN 'recruiter/en', :action => 'mvp_s_recruiter_EN'
    
    fs_mvp_app.mvp_job_seeker_i_want_in 'job_seeker/i_want_in', :action => 'mvp_s_js_i_want_in'
    fs_mvp_app.mvp_recruiter_i_want_in 'recruiter/i_want_in', :action => 'mvp_s_r_i_want_in'
    fs_mvp_app.mvp_job_seeker_thanks 'job_seeker/thanks', :action => 'mvp_s_js_thanks'
    fs_mvp_app.mvp_recruiter_thanks 'recruiter/thanks', :action => 'mvp_s_r_thanks'
    
    # fs_mvp_app.home '', :action => 'mvp_job_seeker'
    
    # fs_mvp_app.fs_mvp 'mvp', :action => 'mvp'
    # fs_mvp_app.mvp_start_over 'start_over', :action => 'mvp_start_over'
    
    # fs_mvp_app.mvp_search_jobs 'search_jobs', :action => 'mvp_search_jobs'
    # fs_mvp_app.mvp_search_job_seekers 'search_job_seekers', :action => 'mvp_search_job_seekers'
    
    # fs_mvp_app.mvp_job_seeker 'job_seeker', :action => 'mvp_job_seeker'
    # fs_mvp_app.mvp_recruitment_agent 'recruitment_agent', :action => 'mvp_recruitment_agent'
    # fs_mvp_app.mvp_hiring_manager 'hiring_manager', :action => 'mvp_hiring_manager'
    # fs_mvp_app.mvp_find_jobs 'find_jobs', :action => 'mvp_find_jobs'
    # fs_mvp_app.mvp_find_job_seekers 'find_job_seekers', :action => 'mvp_find_job_seekers'
    # fs_mvp_app.mvp_job_seeker_i_want_in 'job_seeker/i_want_in', :action => 'mvp_js_i_want_in'
    # fs_mvp_app.mvp_recruitment_agent_i_want_in 'recruitment_agent/i_want_in', :action => 'mvp_ra_i_want_in'
    # fs_mvp_app.mvp_hiring_manager_i_want_in 'hiring_manager/i_want_in', :action => 'mvp_hm_i_want_in'
  end
  
  
  
  #########################
  #   FIVE_SKILLS - ADMIN
  #########################
  
  map.with_options(:controller => 'fs_admin') do |fs_admin|
    
    
    fs_admin.admin_home 'admin/home', :action => 'admin_home'
    
    
    # *** DEMO ***
    fs_admin.demo_job_access 'demo/job/:demo_id', :action => 'demo_job_access'
    fs_admin.demo_job_seeker_access 'demo/job_seeker/:demo_id', :action => 'demo_job_seeker_access'
    # *** DEMO ***
    
    
    fs_admin.admin 'admin/:uid', :action => 'admin_main'
    fs_admin.admin_manage_job_seekers 'admin/job_seeker/all/manage', :action => 'admin_manage_job_seekers'
    fs_admin.admin_manage_companies 'admin/company/all/manage', :action => 'admin_manage_companies'
    fs_admin.admin_manage_agencies 'admin/agency/all/manage', :action => 'admin_manage_agencies'

    fs_admin.admin_manage_jobs 'admin/job/all/manage', :action => 'admin_manage_jobs'
    fs_admin.admin_new_job 'admin/job/new', :action => 'admin_new_job'
    fs_admin.admin_edit_job 'admin/job/:job_id/edit', :action => 'admin_edit_job'
    fs_admin.admin_save_job_ajax 'ajax/admin/job/save', :action => 'admin_save_job_ajax'
      
    fs_admin.admin_manage_templates 'admin/template/all/manage', :action => 'admin_manage_templates'
    fs_admin.admin_new_template 'admin/template/new', :action => 'admin_new_template'
    fs_admin.admin_edit_template 'admin/template/:template_id/edit', :action => 'admin_edit_template'
    fs_admin.admin_save_template_ajax 'ajax/admin/template/save', :action => 'admin_save_template_ajax'
    
    
    fs_admin.admin_god 'admin/god', :action => 'admin_god'
    fs_admin.clone_login 'admin/:user_id/clone_login', :action => 'clone_login'
    
    
    
    fs_admin.admin_keywords 'admin/keywords', :action => 'admin_keywords'
    
    fs_admin.admin_search_keywords 'admin/keywords/search', :action => 'search_keywords'
    fs_admin.admin_save_keyword_replacement 'admin/keyword/replacement', :action => 'save_keyword_replacement'
    
    fs_admin.admin_create_job_profile 'admin/job/create', :action => 'create_job_profile'
    
    fs_admin.admin_tags_demo '/admin/tags/demo', :action => 'tags_demo'
    fs_admin.admin_tags_demo_edit '/admin/tags/demo/edit', :action => 'tags_demo_edit'
    fs_admin.admin_tags_demo_import '/admin/tags/demo/import', :action => 'tags_demo_import'
    fs_admin.admin_search_tags '/admin/tags/search', :action => 'search_tags'
    
  end
  
  
  
  #########################
  #   FIVE_SKILLS - GENERAL
  #########################
  
  map.with_options(:controller => 'five_skills') do |five_skills_app|
    
    
    # --- AJAX
    five_skills_app.ajax_sync 'ajax/sync', :action => 'ajax_sync'
    
    five_skills_app.search_skills_ajax 'ajax/skill/all/search', :action => 'ajax_search_skills'
    five_skills_app.search_organizations_ajax 'ajax/organization/all/search', :action => 'ajax_search_organizations'
    
    
    five_skills_app.privacy_policy '/privacy_policy', :action => 'privacy_policy'
    
    five_skills_app.home '', :action => 'home'
    five_skills_app.five_skills_home '5skills', :action => 'home'
    five_skills_app.reset_user_session 'session/reset', :action => 'reset_user_session'
    
    five_skills_app.test_indeed 'test/indeed', :action => 'TEST_indeed'
    five_skills_app.mechanize 'mechanize', :action => 'mechanize'
    
    
    # ***********************************************************
    # TEMPLATES
    # ***********************************************************
    five_skills_app.create_template 'template/create', :action => 'create_template'
    five_skills_app.view_template 'template/view', :action => 'view_template'
    
    
    # ***********************************************************
    # FILES
    # ***********************************************************
    five_skills_app.download_file 'file/:file_id/download', :action => 'download_file'
    five_skills_app.show_file 'file/:file_id/show', :action => 'show_file'
    
    
    five_skills_app.list 'job/list', :action => 'list'
    # five_skills_app.five_skills_profile ':profile_name', :action => 'public_profile'
  end



  # ***********************************************************
  # ORGANISATION
  # ***********************************************************
    
  map.with_options(:controller => 'fs_organisation') do |fs_organisation|

    fs_organisation.view_company_summary 'company/view/summary', :action => 'view_company_summary'
    fs_organisation.view_agency_summary 'agency/view/summary', :action => 'view_agency_summary'
    
  end
  
  

  # ***********************************************************
  # JOBS
  # ***********************************************************
    
  map.with_options(:controller => 'fs_job') do |fs_job|
    
    
    # *** Dec 2013
    fs_job.a_recruiter_home 'a/recruiter', :action => 'a_recruiter_home'
    fs_job.a_recruiter_publish_job 'a/recruiter/job/publish', :action => 'a_recruiter_publish_job'
    fs_job.a_recruiter_job_publishing_home 'a/recruiter/job/publishing_home', :action => 'a_recruiter_job_publishing_home'
    
    fs_job.a_fajax_publish_job 'fajax/job/publish', :action => 'fajax__publish_job'
    fs_job.ajax_publish_job 'ajax/a/recruiter/job/publish', :action => 'ajax_a_recruiter_publish_job'
    
    fs_job.a_recruiter__do_linkedin_login 'a/recruiter/login/linkedin', :action => 'a_recruiter__do_linkedin_login'
    fs_job.a_recruiter_restart 'a/recruiter/restart', :action => 'a_recruiter_restart'
    
    fs_job.get_linkedin_groups 'ajax/linkedin/groups', :action => 'ajax_get_linkedin_groups'
    fs_job.get_job_status 'ajax/job/status', :action => 'ajax_get_job_status'
    
    
    
    # *** AJAX ***
    fs_job.save_job_fs_profile 'ajax/job/save', :action => 'ajax_save_job_fs_profile'
    fs_job.social_groups 'ajax/social/groups', :action => 'ajax_get_social_groups'
    fs_job.post_job_to_social_group 'ajax/social/group/post/job', :action => 'ajax_post_job_to_social_group'
    
    fs_job.get_job_publishing_info 'ajax/job/publishing/info', :action => 'ajax_get_job_publishing_info'
    fs_job.publish_job 'ajax/job/publish', :action => 'ajax_publish_job'
    

    fs_job.recruiter_home 'recruiter/home', :action => 'recruiter_home'


    fs_job.job_seekers_cv_delivery_log 'job_seekers/cv_delivery/log', :action => 'job_seekers_cv_delivery_log'
    
    fs_job.find_jobs 'job/find', :action => 'find_jobs'
    fs_job.search_jobs 'job/search', :action => 'search_jobs'
    
    fs_job.create_job_profile 'job/create', :action => 'create_job_profile'
    fs_job.save_job_profile 'job/save', :action => 'save_job_profile'
    fs_job.view_job_profile 'job/:job_id/view', :action => 'view_job_profile'
    fs_job.edit_job_profile 'job/:job_id/edit', :action => 'edit_job_profile'
    fs_job.update_job_profile 'job/update', :action => 'update_job_profile'
    
    fs_job.apply_for_job 'job/:job_id/apply', :action => 'apply_for_job'
    fs_job.send_job_application 'job/:job_id/send_application', :action => 'send_job_application'
    
    fs_job.request_cv_from_job_seeker 'job_seeker/:job_seeker_id/request_cv', :action => 'request_cv_from_job_seeker'
    
    fs_job.view_job_seeker_matches 'job_seeker/matches', :action => 'view_job_seeker_matches'
    fs_job.manage_job_settings 'job/settings/manage', :action => 'manage_job_settings'
    fs_job.update_job_settings 'job/settings/update', :action => 'update_job_settings'
    
    fs_job.disable_job_profile 'job/:job_id/disable', :action => 'disable_job_profile'
    fs_job.enable_job_profile 'job/:job_id/enable', :action => 'enable_job_profile'
    fs_job.delete_job_profile 'job/:job_id/delete', :action => 'delete_job_profile'
    fs_job.remove_job_profile 'job/remove', :action => 'remove_job_profile'
  end


  
  # ***********************************************************
  # JOB SEEKERS
  # ***********************************************************
    
  map.with_options(:controller => 'fs_job_seeker') do |fs_job_seeker|
    
    
    fs_job_seeker.a_recruiter__view_job_post 'a/recruiter/job_post/:job_ref_key', :action => 'a_recruiter__view_job_post'
    
    
    # *** AJAX ***
    fs_job_seeker.save_job_seeker_fs_profile 'ajax/job_seeker/save', :action => 'ajax_save_job_seeker_fs_profile'
    fs_job_seeker.search_job_seekers 'ajax/job_seeker/search', :action => 'ajax_search_job_seekers'
    fs_job_seeker.i_want_more_jobs 'ajax/job_seeker/i_want_more_jobs', :action => 'ajax_i_want_more_jobs'
    
    
    # *** FAJAX ***
    fs_job_seeker.fajax_send_job_post_application 'fajax/job_post/:job_ref_key/application/send', :action => 'fajax_send_job_post_application'
    fs_job_seeker.fajax_job_seeker_sign_up 'fajax/job_seeker/signup', :action => 'fajax_job_seeker_sign_up'
    
    
    fs_job_seeker.seeker_home 'seeker/home', :action => 'seeker_home'
    fs_job_seeker.view_job_post 'job_post/:job_ref_key', :action => 'view_job_post'
    fs_job_seeker.ajax_apply_to_job_post 'ajax/job_post/:job_ref_key/apply', :action => 'ajax_apply_to_job_post'
    
    
    
    fs_job_seeker.view_seeker_profile 'seeker/profile/view', :action => 'view_seeker_profile'
    fs_job_seeker.view_seeker_profile_by_recruiter 'seeker/:seeker_id/profile/view', :action => 'view_seeker_profile_by_recruiter'
    fs_job_seeker.seek_job_seekers 'seekers/seek', :action => 'seek_job_seekers'
    
    fs_job_seeker.linkedin_catchup 'linkedin/catchup', :action => 'linkedin_catchup'
    fs_job_seeker.linkedin_catchup_all_connections 'linkedin/catchup/connections', :action => 'linkedin_catchup_all_connections'
    fs_job_seeker.scraper_catchup 'scraper/catchup', :action => 'scraper_catchup'
    
    
    fs_job_seeker.jobs_cv_delivery_log 'jobs/cv_delivery/log', :action => 'jobs_cv_delivery_log'
    
    fs_job_seeker.find_job_seekers 'job_seeker/find', :action => 'find_job_seekers'
    
    
    
    fs_job_seeker.create_job_seeker_profile 'job_seeker/create', :action => 'create_job_seeker_profile'
    fs_job_seeker.save_job_seeker_profile 'job_seeker/save', :action => 'save_job_seeker_profile'
    fs_job_seeker.view_job_seeker_profile 'job_seeker/:job_seeker_id/view', :action => 'view_job_seeker_profile'
    fs_job_seeker.edit_job_seeker_profile 'job_seeker/:job_seeker_id/edit', :action => 'edit_job_seeker_profile'
    fs_job_seeker.update_job_seeker_profile 'job_seeker/update', :action => 'update_job_seeker_profile'
    
    fs_job_seeker.send_cv_to_job 'job/:job_id/send_cv', :action => 'send_cv_to_job'
    fs_job_seeker.cv_request_approve 'job/:job_id/cv_request/approve', :action => 'cv_request_approve'
    fs_job_seeker.cv_request_reject 'job/:job_id/cv_request/reject', :action => 'cv_request_reject'
    
    fs_job_seeker.view_job_matches 'job/matches', :action => 'view_job_matches'
    fs_job_seeker.manage_job_seeker_settings 'job_seeker/settings/manage', :action => 'manage_job_seeker_settings'
    fs_job_seeker.update_job_seeker_settings 'job_seeker/settings/update', :action => 'update_job_seeker_settings'
    
    fs_job_seeker.disable_job_seeker_profile 'job_seeker/:job_seeker_id/disable', :action => 'disable_job_seeker_profile'
    fs_job_seeker.enable_job_seeker_profile 'job_seeker/:job_seeker_id/enable', :action => 'enable_job_seeker_profile'
    fs_job_seeker.delete_job_seeker_profile 'job_seeker/:job_seeker_id/delete', :action => 'delete_job_seeker_profile'
    fs_job_seeker.remove_job_seeker_profile 'job_seeker/remove', :action => 'remove_job_seeker_profile'
  end  
  
  map.with_options(:controller => 'fs_login') do |fs_login|
    fs_login.do_login '5skills/login', :action => 'do_login'
    fs_login.do_logout '5skills/logout', :action => 'do_logout'
    fs_login.do_register '5skills/register', :action => 'do_register'
    
    fs_login.remove_entity 'remove/entity', :action => 'remove_entity'
    
    fs_login.do_linkedin_login 'login/linkedin', :action => 'do_linkedin_login'
    fs_login.linkedin_auth_cancel 'login/linkedin/cancel', :action => 'linkedin_auth_cancel'
    fs_login.linkedin_auth_accept 'login/linkedin/accept', :action => 'linkedin_auth_accept'
    
    fs_login.linkedin_auth_accept_2 'login/linkedin/accept/2', :action => 'linkedin_auth_accept_2'
  end
  
  map.with_options(:controller => 'bookmarklet') do |bookmarklet|
#    bookmarklet.bl_parse_site 'bookmarklet/parse_site', :action => 'bl_parse_site'

    bookmarklet.bl_login 'bookmarklet/login', :action => 'bl_login'
    bookmarklet.bl_logout 'bookmarklet/logout', :action => 'bl_logout'
    bookmarklet.bl_process_login 'bookmarklet/process_login', :action => 'bl_process_login'
    bookmarklet.bl_bookmark_site 'bookmarklet/bookmark_site', :action => 'bl_bookmark_site'
    bookmarklet.bl_process_bookmark_site 'bookmarklet/process_bookmark_site', :action => 'bl_process_bookmark_site'
    
    # ------------------------------------ TESTS ------------------------------------
    bookmarklet.bl_parse_page 'bookmarklet/parse_page', :action => 'bl_parse_page'
    bookmarklet.bl_actions 'bookmarklet/actions', :action => 'bl_actions'
    bookmarklet.bl_job_ad 'bookmarklet/job_ad', :action => 'bl_job_ad'
    bookmarklet.bl_json_test 'bookmarklet/json_test', :action => 'bl_json_test'
    # ------------------------------------ TESTS ------------------------------------
    
    # ------------------------------------ SESSION-BASED ACTIONS ------------------------------------
    bookmarklet.bl_social_post 'bookmarklet/social/post', :action => 'bl_social_post'
    bookmarklet.bl_prepare_post 'bookmarklet/social/post/prepare', :action => 'bl_prepare_post'
    
    bookmarklet.bl_check_session 'bookmarklet/check_session', :action => 'bl_check_session'
    bookmarklet.bl_social_login 'bookmarklet/social_login', :action => 'bl_social_login'
    bookmarklet.bl_notify_login 'bookmarklet/notify_login', :action => 'bl_notify_login'
    bookmarklet.bl_notify_logout 'bookmarklet/notify_logout', :action => 'bl_notify_logout'
    # ------------------------------------ SESSION-BASED ACTIONS ------------------------------------

    # ------------------------------------ USER ACTIONS ------------------------------------
    bookmarklet.bl_save_job 'bookmarklet/job/save', :action => 'bl_save_job'
    bookmarklet.bl_save_jobs 'bookmarklet/jobs/save', :action => 'bl_save_jobs'
    
                          # ------------- PANELS -------------
    bookmarklet.bl_get_search_results_panel 'bookmarklet/panel/search_results', :action => 'bl_get_search_results_panel'
    bookmarklet.bl_get_job_panel 'bookmarklet/panel/job', :action => 'bl_get_job_panel'
    bookmarklet.bl_get_apply_panel 'bookmarklet/panel/apply', :action => 'bl_get_apply_panel'
    bookmarklet.bl_get_unknown_panel 'bookmarklet/panel/unknown', :action => 'bl_get_unknown_panel'
    bookmarklet.bl_get_new_role_panel 'bookmarklet/panel/new_role', :action => 'bl_get_new_role_panel'
    bookmarklet.bl_get_actions_panel 'bookmarklet/panel/actions', :action => 'bl_get_actions_panel'
    
    bookmarklet.bl_get_facebook_panel 'bookmarklet/panel/facebook', :action => 'bl_get_facebook_panel'
                          # ------------- PANELS -------------    
    
    # ------------------------------------ USER ACTIONS ------------------------------------
    
    # ------------------------------------ ADMIN ------------------------------------
    bookmarklet.bl_admin_save_page 'bookmarklet/admin/save_page', :action => 'bl_admin_save_page'
    bookmarklet.bl_admin_get_field_details 'bookmarklet/admin/field/details', :action => 'bl_admin_get_field_details'
    bookmarklet.bl_admin_save_field 'bookmarklet/admin/field/save', :action => 'bl_admin_save_field'
    
                          # ------------- PANELS -------------
    bookmarklet.bl_admin_get_site_and_page_details 'bookmarklet/admin/panel/site_and_page_details', :action => 'bl_admin_get_site_and_page_details'
    bookmarklet.bl_admin_get_page_fields_details 'bookmarklet/admin/panel/fields_details', :action => 'bl_admin_get_page_fields_details'
                          # ------------- PANELS -------------

    # ------------------------------------ ADMIN ------------------------------------
    
  end
  
  map.with_options(:controller => 'files') do |files|
    
    files.view_files 'files', :action => 'view_files'
    files.create_file_quick 'file/create/quick', :action => 'create_file_quick'
    
  end
  
  map.with_options(:controller => 'account') do |account|
    account.register_candidate 'candidate/register', :action => 'register_candidate'
    account.process_registration 'registration/process', :action => 'process_registration'
    
    account.forgot_password 'password/forgot', :action => 'forgot_password'
    account.process_forgot_password 'process/forgot_password', :action => 'process_forgot_password'
    account.forgot_password_email_sent 'password/sent', :action => 'forgot_password_email_sent'
    
    account.process_registration_confirmation 'confirm/:confirmation_key', :action => 'process_registration_confirmation'
    account.finish_registration_confirmation 'registration/confirmed', :action => 'finish_registration_confirmation'
    account.email_confirm_sent 'registration/confirmation_email_sent', :action => 'email_confirm_sent'    
  end
  
#
# Mapping of 'Registration and Login Controller'
#
  map.with_options(:controller => 'login') do |login|
    login.login 'login', :action => 'login'
    login.process_login 'login/process', :action => 'process_login'
    login.logout 'logout', :action => 'logout'
    
    # AJAX Test
    login.add 'add', :action => 'add'
    login.ajax_test 'ajax/test', :action => 'ajax_test'
  end

  #
# Mapping of
#
  map.with_options(:controller => 'application') do |app|
    # app.home '', :action => 'home'
  end
  
  map.with_options(:controller => 'admin_login') do |admin_login|
    # admin_login.admin_home 'admin', :action => 'admin_home'
    admin_login.process_login 'admin/login', :action => 'process_login'
    admin_login.process_change_password 'admin/change_password', :action => 'process_change_password'
    
    admin_login.admin_logout 'admin_logout', :action => 'admin_logout'
 
    # The following will be used to perform hacks, workarounds, when things get stuck (e.g. DB migration don't work properly ;-)')
    admin_login.admin_hack 'admin_hack', :action => 'admin_hack'
  end
  
  map.with_options(:controller => 'admin_messages') do |admin_messages|    
    admin_messages.admin_view_inbox_message 'admin/messages/inbox/:message_id/view', :action => 'admin_view_inbox_message'
    admin_messages.admin_view_sent_message 'admin/messages/sent/:message_id/view', :action => 'admin_view_sent_message'
    
    admin_messages.admin_view_inbox_messages 'admin/messages/inbox/:p', :action => 'admin_view_inbox_messages'
    admin_messages.admin_view_inbox_messages 'admin/messages/inbox', :action => 'admin_view_inbox_messages'
    admin_messages.admin_view_sent_messages 'admin/messages/sent', :action => 'admin_view_sent_messages'
    
    admin_messages.admin_reply_to_message 'admin/messages/inbox/:message_id/reply', :action => 'admin_reply_to_message'
    admin_messages.admin_send_reply_to_message 'admin/messages/inbox/:message_id/reply/send', :action => 'admin_send_reply_to_message'
  end
  
  
  
  # ***************************
  # AGENT INTERFACE
  # ***************************
  
  map.with_options(:controller => 'agent_main') do |agent_main|
    agent_main.agent_view_home 'agent', :action => 'view_agent_home'
  end  
  
  map.with_options(:controller => 'agent_roles') do |agent_roles|
    agent_roles.agent_view_roles 'agent/roles', :action => 'view_agent_roles'
  end
  
  
  
  # ***************************
  # COMPANY CONTACT INTERFACE
  # ***************************
  
  map.with_options(:controller => 'company_contact_main') do |company_contact_main|
    company_contact_main.company_contact_view_home 'company_contact', :action => 'view_company_contact_home'
  end  
  
  map.with_options(:controller => 'company_contact_role') do |company_contact_role|
    company_contact_role.company_contact_view_roles 'company_contact/roles', :action => 'view_company_contact_roles'
    
    company_contact_role.company_contact_view_role 'company_contact/role', :action => 'view_company_contact_role'
    company_contact_role.company_contact_view_role_description 'company_contact/role/description', :action => 'view_company_contact_role_description'
    company_contact_role.company_contact_view_role_agents 'company_contact/role/agents', :action => 'view_company_contact_role_agents'
    company_contact_role.company_contact_view_role_candidates 'company_contact/role/candidates', :action => 'view_company_contact_role_candidates'
    
    company_contact_role.company_contact_view_role_filtered 'company_contact/role/filtered', :action => 'view_company_contact_role_filtered'
  end
  
  map.with_options(:controller => 'company_contact_agent') do |company_contact_agent|    
    company_contact_agent.view_company_contact_agent 'company_contact/agent', :action => 'view_company_contact_agent'
    company_contact_agent.view_company_contact_agent_candidates 'company_contact/agent/candidates', :action => 'view_company_contact_agent_candidates'
    company_contact_agent.view_company_contact_agent_roles 'company_contact/agent/roles', :action => 'view_company_contact_agent_roles'
    
    company_contact_agent.view_company_contact_agent_filtered 'company_contact/agent/filtered', :action => 'view_company_contact_agent_filtered'
    company_contact_agent.view_company_contact_agent_filtered_candidates 'company_contact/agent/filtered/candidates', :action => 'view_company_contact_agent_filtered_candidates'
  end
  
  map.with_options(:controller => 'company_contact_candidate') do |company_contact_candidate|
    company_contact_candidate.view_company_contact_candidate_filtered 'company_contact/candidate/filtered', :action => 'view_company_contact_candidate_filtered'
  end
  
  map.with_options(:controller => 'company_contact_invitation') do |company_contact_invitation|
    company_contact_invitation.invite_company_contact_agents_by_email_step_1 'company_contact/invite/agents/email/step_1', :action => 'invite_company_contact_agents_by_email_step_1'
    company_contact_invitation.invite_company_contact_agents_by_email_step_2 'company_contact/invite/agents/email/step_2', :action => 'invite_company_contact_agents_by_email_step_2'
    company_contact_invitation.invite_company_contact_agents_by_email_step_3 'company_contact/invite/agents/email/step_3', :action => 'invite_company_contact_agents_by_email_step_3'
    
    company_contact_invitation.invite_company_contact_agents_by_search_step_1_agencies 'company_contact/invite/agents/search/step_1/agencies', :action => 'invite_company_contact_agents_by_search_step_1_agencies'
    company_contact_invitation.invite_company_contact_agents_by_search_step_1_agents 'company_contact/invite/agents/search/step_1/agents', :action => 'invite_company_contact_agents_by_search_step_1_agents'
    company_contact_invitation.invite_company_contact_agents_by_search_step_2 'company_contact/invite/agents/search/step_2', :action => 'invite_company_contact_agents_by_search_step_2'
  end
  
  map.with_options(:controller => 'company_contact_message') do |company_contact_message|
    company_contact_message.view_company_contact_uncategorised_senders 'company_contact/messages/senders/uncategorised', :action => 'view_company_contact_uncategorised_senders'
    company_contact_message.review_company_contact_categorised_senders 'company_contact/messages/senders/categorised/review', :action => 'review_company_contact_categorised_senders'
    
    company_contact_message.manage_company_contact_message_associations 'company_contact/message/associations', :action => 'manage_company_contact_message_associations'
    company_contact_message.add_company_contact_message_association 'company_contact/message/association/add', :action => 'add_company_contact_message_association'
  end
  
  
  map.with_options(:controller => 'test_stuff') do |test|
    test.fck_editor 'fck_editor', :action => 'fck_editor'
  end  
  
  # You can have the root of your site routed with map.root -- just remember to delete public/index.html.
  map.root :controller => 'five_skills', :action => 'public_profile'





  # map.resources :people

  # The priority is based upon order of creation: first created -> highest priority.

  # Sample of regular route:
  #   map.connect 'products/:id', :controller => 'catalog', :action => 'view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   map.purchase 'products/:id/purchase', :controller => 'catalog', :action => 'purchase'
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   map.resources :products

  # Sample resource route with options:
  #   map.resources :products, :member => { :short => :get, :toggle => :post }, :collection => { :sold => :get }

  # Sample resource route with sub-resources:
  #   map.resources :products, :has_many => [ :comments, :sales ], :has_one => :seller
  
  # Sample resource route with more complex sub-resources
  #   map.resources :products do |products|
  #     products.resources :comments
  #     products.resources :sales, :collection => { :recent => :get }
  #   end

  # Sample resource route within a namespace:
  #   map.namespace :admin do |admin|
  #     # Directs /admin/products/* to Admin::ProductsController (app/controllers/admin/products_controller.rb)
  #     admin.resources :products
  #   end



  # See how all your routes lay out with "rake routes"

  # Install the default routes as the lowest priority.
  # Note: These default routes make all actions in every controller accessible via GET requests. You should
  # consider removing the them or commenting them out if you're using named routes and resources.
  #map.connect ':controller/:action/:id'
  #map.connect ':controller/:action/:id.:format'
  
#  map.connect 'bookmarklet/json_test', :controller => 'bookmarklet', :action => 'bl_json_test', :conditions => { :method => :post }
#  map.connect 'bookmarklet/json_test', :controller => 'bookmarklet', :action => 'bl_json_test', :conditions => { :method => :options }
  
end
