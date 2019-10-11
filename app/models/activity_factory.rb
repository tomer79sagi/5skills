class ActivityFactory < ActiveForm
   
  def self.create_o(params_h, friendly_names_h, user_id = nil)
    @activity = Activity.new
    
    @activity.action = params_h[:action]
    @activity.controller = params_h[:controller]
    @activity.person_id = user_id if user_id
    
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
  
  def self.to_link_to_options(activity)
    @link_to_h = {:controller => activity.controller, :action => activity.action}
                    
    if activity.parameter_names && !activity.parameter_names.empty?
      @par_names_a = activity.parameter_names.split(",")
      @par_ids_a = activity.parameter_ids.split(",")  

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
  # This map will map system actions to user friendly actions.
  # This array is useful for when the user wants to return to the previous screen.
  #
  def self.actions
    
      # Syntax of array below: [ {action_name}, {action_friendly_name}, 
      #                          {entity_type}, {entity_view_mode} ]
      
      #  1 - Entity type (application, agency, note etc)
      #  2 - Entity view mode (new, save, view, edit, update)

      # Entity types could be one of the following:
      #  0 - General
      #  1 - Job Application
      #  2 - Agency
      #  3 - Company
      #  4 - Contact
      #  5 - Note
      #  6 - Other
      #
      # ** Explore chaining of entities for activity logging purposes ??

      # Entity view modes could be one of the following:
      #  1 - New 
      #  2 - Save
      #  3 - View
      #  4 - Edit
      #  5 - Update
      #  6 - Delete
    
      [
      
      # Applications
      
      ['view_applications', 'View job applications', 1, 3],
      
      ['new_job', 'Create a new job application', 1, 1],
      ['create_application_quick', 'Create a new job application quickly', 1, 1],
      ['save_application', 'Save job application', 1, 2], 
      
      ['view_application', 'View job application', 1, 3],
      ['edit_application', 'Edit job application', 1, 4],
      ['update_application', 'Update job application', 1, 5],
      ['delete_job', 'Delete job application', 1, 6],
      
      ['view_application_agency', 'View job application''s agency', 1, 3],
      ['edit_application_agency', 'Edit job application''s agency', 1, 4],
      ['update_application_agency', 'Update job application''s agency', 1, 5],
      
      ['view_application_company', 'View job application''s company', 1, 3],
      ['edit_application_company', 'Edit job application''s company', 1, 4],
      ['update_application_company', 'Update job application''s company', 1, 5],
      
      ['edit_application_status', 'Edit job application''s status', 1, 4],
      ['update_application_status', 'Update job application''s status', 1, 5],
      
      # Application Notes
      
      ['view_application_notes', 'View application notes', 1, 3],
      
      ['new_application_note', 'Create a new job application note', 1, 1],
      ['create_application_note', 'Create a new job application note', 1, 1], # *** Duplicate of 'new_application_note' ***
      ['create_application_note_quick', 'Create a new job application note quickly', 1, 1],
      ['save_application_note', 'Save job application note', 1, 2],
      
      ['view_application_note', 'View job application note', 1, 3],
      ['edit_application_note', 'Edit job application note', 1, 4],
      ['update_application_note', 'Update job application note', 1, 5],
      ['delete_application_note', 'Delete job application note', 1, 6]
      
      ]
      
  end
  
end
