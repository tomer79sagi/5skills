class Activity < ActiveRecord::Base
  
  #
  # 'person_o' is the 'user' object that will be used to 'link' the activity to the user
  # This static method is also used by 'my_mailer_action', it provides the option to send a 'nil' person_o object
  # This method can therefore create 'independent' activities, i.e. not attached to a particular person.
  #
  def self.create_o(params_h, friendly_names_h, person_o = nil)
    @activity = Activity.new
    @activity.person_id = 0 # in case there is no current logged in user
    
    @activity.action = params_h[:action]
    @activity.controller = params_h[:controller]
    @activity.person_id = person_o.id if person_o
    
    @parameters_h = params_h.select {|k, v| k.to_s.include? "_id"}
    
    #puts "  --- Action: " + params_h[:action].to_s
    #puts "  --- Controller: " + params_h[:controller].to_s
    
    if !@parameters_h.empty?
      
      @friendly_names_a = Array.new
      
      # Create array of 2 elements where each element is the array of either the IDs or the Names
      @parameters_h = @parameters_h.transpose
      
      # Retrieve the 1st element (i.e. array of all IDs)
      @ids = @parameters_h[0]
      @activity.parameter_ids = @ids.join(",")
      
      # Retrieve the 2nd element (i.e. array of all Names)
      @activity.parameter_names = @parameters_h[1].join(",")
      
      # Populate an Array for the friendly_names with the same index values as the @ids array
      # This will help assigning and retrieving the right information for the right elements
      if friendly_names_h
        friendly_names_h.each {|k, v|
          @id_index = @ids.index(k)
          
          @friendly_names_a[@id_index] = v if @id_index
        }
              
        @activity.parameter_values = @friendly_names_a.join(",")
      end
      
      #puts "  --- activity: " + @activity.parameter_ids
      #puts "  --- activity: " + @activity.parameter_names
      #puts "  --- activity: " + @activity.parameter_values
    end
    
    @activity
  end
  
  def to_link_to_options
    @link_to_h = {:controller => controller, :action => action}
                    
    if self.parameter_names && !self.parameter_names.empty?
      @par_names_a = self.parameter_names.split(",")
      @par_ids_a = self.parameter_ids.split(",")  

      @par_ids_a.each_index {|index| @link_to_h[@par_ids_a[index]] = @par_names_a[index]}
    end
    
    @link_to_h
  end
  
  def to_url
    
  end
  
  def touch
    updated_at_will_change!
    save  
  end
  
  #
  # This map will map system actions to user friendly activities.
  # This Hash will be used to store the friendly actions taken
  #
  # Syntax of elements below:
  #  {action_name} => 
  #     [ {action_friendly_name},
  #       {entity_type}, 
  #       {entity_view_mode},
  #       {is_primary_view [0 or 1]} ]
  
  #  1 - Entity type (application, agency, note etc)
  #  2 - Entity view mode (new, save, view, edit, update)
  #  3 - View type (1 - Primary: e.g. Agency, Application, Role, 
  #        0: Secondary - e.g. Feedback, Contact Us [
  #           This is used to set if the system should store a 'return-to' link if a 'secondary' page was used.
  #           When existing a secondary link, the system will rerieve the last 'primary' view and render it.]
  #        2: Dynamic - e.g. Alternating using AJAX)

  # Entity types could be one of the following:
  #  0 - General
  #  1 - Job Application
  #  2 - Agency
  #  3 - Company
  #  4 - Contact
  #  5 - General (e.g. Contact Us, Feedback)
  #  6 - Application Notes
  #  7 - File
  #
  # ** Explore chaining of entities for activity logging purposes ??

  # Entity view modes could be one of the following:
  #  1 - New 
  #  2 - Save
  #  3 - View
  #  4 - Edit
  #  5 - Update
  #  6 - Delete
  #  7 - Send
  def self.activities
    {
    
    # Files

    "view_files" => ['View files', 7, 3, 1],
    "create_file_quick" => ['Create a file quickly', 7, 1, 1],

    # Applications
    
    "view_applications" => ['View job applications', 1, 3, 1],
      
    "new_job" => ['Create a new job application', 1, 1, 1],
    "create_application_quick" => ['Create a new job application quickly', 1, 1, 1],
    "save_application" => ['Save job application', 1, 2, 1], 
    
    "view_application" => ['View job application', 1, 3, 1],
    "edit_application" => ['Edit job application', 1, 4, 1],
    "update_application" => ['Update job application', 1, 5, 1],
    "delete_job" => ['Delete job application', 1, 6, 1],
    
    "view_application_agency" => ['View job application''s agency', 1, 3, 1],
    "edit_application_agency" => ['Edit job application''s agency', 1, 4, 1],
    "update_application_agency" => ['Update job application''s agency', 1, 5, 1],
    
    "view_application_company" => ['View job application''s company', 1, 3, 1],
    "edit_application_company" => ['Edit job application''s company', 1, 4, 1],
    "update_application_company" => ['Update job application''s company', 1, 5, 1],
    
    "edit_application_status" => ['Edit job application''s status', 1, 4, 1],
    "update_application_status" => ['Update job application''s status', 1, 5, 1],
    
    # Application Notes
      
    "view_application_notes" => ['View application notes', 6, 3, 1],
    
    "new_application_note" => ['Create a new job application note', 6, 1, 1],
    "create_application_note" => ['Create a new job application note', 6, 1, 1], # *** Duplicate of 'new_application_note' ***
    "create_application_note_quick" => ['Create a new job application note quickly', 6, 1, 1],
    "save_application_note" => ['Save job application note', 6, 2, 1],
    
    "view_application_note" => ['View job application note', 6, 3, 1],
    "edit_application_note" => ['Edit job application note', 6, 4, 1],
    "update_application_note" => ['Update job application note', 6, 5, 1],
    "delete_application_note" => ['Delete job application note', 6, 6, 1],
    
    # Contacts
    
    "delete_contact" => ['Delete organisation contact', 4, 6, 1],
    "edit_contact" => ['Edit organisation contact', 4, 4, 1],
    "update_contact" => ['Update organisation contact', 4, 5, 1],
    
    "view_organisation_contacts" => ['View organisation contacts', 4, 3, 1],
    "new_organisation_contact" => ['Create a new organisation contact', 4, 1, 1],
    "save_organisation_contact" => ['Save organisation contact', 4, 2, 1],

    # Companies

    "view_companies" => ['View companies', 4, 3, 1],
    "create_company_quick" => ['Create a new company quickly', 6, 1, 1],
    "new_company" => ['Create a new company', 6, 1, 1],
    "save_company" => ['Save a company', 4, 2, 1],

    # Agencies

    "view_agencies" => ['View agencies', 4, 3, 1],
    "create_agency_quick" => ['Create a new agency quickly', 6, 1, 1],
    "new_agency" => ['Create a new agency', 6, 1, 1],
    "save_agency" => ['Save an agency', 4, 2, 1],

    # Organisations

    "view_organisations" => ['View organisations', 4, 3, 1],
    "create_organisation_quick" => ['Create a new organistion quickly', 6, 1, 1],
    
    "view_organisation" => ['View organisation', 6, 3, 1],
    "edit_organisation" => ['Edit organisation', 6, 4, 1],
    "update_organisation" => ['Update organisation', 6, 5, 1],
    "new_organisation" => ['Create a new organisation', 6, 1, 1],
    "save_organisation" => ['Save organisation', 6, 2, 1],
    "delete_organisation" => ['Delete organisation', 6, 6, 1],

    # User Messages

#    "view_inbox_messages" => ['View orgagnisations', 4, 3, 1],
    "view_sent_messages" => ['View orgagnisations', 4, 3, 1],
    
    "view_inbox_message" => ['View organisation', 6, 3, 1],
    "view_sent_message" => ['View organisation', 6, 3, 1],
    
    "reply_to_message" => ['Create a new organisation', 6, 1, 1],
    "send_reply_to_message" => ['Save organisation', 6, 2, 1],

    # MyMailer

    # Bookmarklet

    "bl_parse_page" => ['Parse site', 0, 7, 1],
    "bl_bookmark_site" => ['Bookmark site', 0, 7, 1],
    "bl_process_bookmark_site" => ['Process bookmark site', 0, 7, 0],
    
    "bl_login" => ['View login', 0, 3, 0],
    "bl_process_login" => ['Perform Bookmarklet Login', 0, 7, 0],
    "bl_logout" => ['Perform logout', 0, 7, 0],
    
    "bl_actions" => ['Display actions panel', 0, 7, 2],
    "bl_job_ad" => ['Display job ad panel', 0, 7, 2],

    # Login

#    "process_beta 'beta/process', :action => 'process_beta'
#    "beta 'beta', :action => 'beta'
#    "logout_beta 'logout_beta', :action => 'logout_beta'
    
    "login" => ['View login', 0, 3, 0],
    "register_candidate" => ['View register candidate', 0, 3, 0],
    "process_login" => ['Perform login', 0, 7, 0],
    "process_registration" => ['Perform registration', 0, 7, 0],
    "logout" => ['Perform logout', 0, 7, 0],
    
    "forgot_password" => ['View forgot password', 0, 3, 0],
    "process_forgot_password" => ['Process forgot password', 0, 7, 0],
    "forgot_password_email_sent" => ['View password email sent page', 0, 3, 0],
    
    "process_registration_confirmation" => ['Confirm registration', 0, 7, 0],
    "finish_registration_confirmation" => ['Registration completed', 0, 3, 0],
    "email_confirm_sent" => ['Email confirmation sent', 0, 7, 0],
        
    # General Application

    "provide_feedback" => ['Provide feedback', 5, 1, 0],
    "send_feedback" => ['Send feedback', 5, 7, 0],
    
    # General
    
    "contact_us" => ['Request to send a ''Contact Us'' message', 5, 1, 0],
    "send_contact_us" => ['Send a ''Contact Us'' message', 5, 7, 0],
    
    "about_us" => ['View ''About Us'' page', 5, 3, 0],
    "home" => ['View ''Homepage'' page', 5, 3, 1],    
    
    }
  end
  
end
