#
# CONSTANTS DEFINTIONS
#
# Status:
#  1 - New
#  2 - Registered
#  3 - Confirmed : email confirmed
#  4 - Must change password
#
# Person_Type:
#  0 - Website role (e.g. admin, support etc)
#  1 - Candidate
#  2 - Agent
#  3 - Company Contact
#
# Organisation_Type:
#  1 - Agency
#  2 - Company
#
# Role_Application_Status:
#  1 - Created
#  2 - Sent
#  3 - Short Listed
#  4 - Interview Scheduled : could be a few interviews
#  5 - Waiting Decision : could be a few interviews
#  6 - Offer Made
#  7 - Accepted Offer
#  8 - Rejected Offer
#  9 - Application Declined
#
# Session[:mode]
#  1 - Create
#  2 - Update
#
class AgentMainController < ApplicationController
    
  def prep_view_applications
    
    prep_sorting_info(RoleApplication::sort_mapping, "update_date", "down")
    
    # ******************************
    # Initialize the QUICK add area
    # ******************************

    @quick_add_agencies = Organisation.agencies_for_select(session[:user].id)
    
#    # Get all agencies
#    @quick_add_agencies = Organisation.find_by_sql("SELECT DISTINCT " +
#        "O_Agency.id, " +
#        "O_Agency.name " +
#      "from " +
#        "person_to_organisations PTO, " +
#        "organisations O_Agency " +
#      "where " +
#        "O_Agency.type_id = 1 and " + # 1 = Agency
#        "O_Agency.id = PTO.organisation_id and " +
#        "PTO.person_id = " + session[:user].id.to_s + " " + 
#        "order by name asc")     
#        
#    @quick_add_agencies = @quick_add_agencies.collect {|agency| [ agency.name, agency.id ]}
#    
#    # [X, Y] : X = index, Y = length. If legnth is '0', it's INSERT %>
#    # Outer '[]' is for array, inner '[]' is for element within array
#    @quick_add_agencies[0,0] = [['-- N/A --',0], ["-- New Agency --", -2],['', -1]]
    
    @quick_add_companies = Organisation.companies_for_select(session[:user].id)
    
#    # Get all companies
#    @quick_add_companies = Organisation.find_by_sql("SELECT DISTINCT " +
#        "O_Company.id, " +
#        "O_Company.name " +
#      "from " +
#        "person_to_organisations PTO, " +
#        "organisations O_Company " +
#      "where " +
#        "O_Company.type_id = 2 and " + # 2 = Company
#        "O_Company.id = PTO.organisation_id and " +
#        "PTO.person_id = " + session[:user].id.to_s + " " + 
#        "order by name asc")    
#        
#    @quick_add_companies = @quick_add_companies.collect {|company| [ company.name, company.id ]}
#    
#    # [X, Y] : X = index, Y = length. If legnth is '0', it's INSERT %>
#    # Outer '[]' is for array, inner '[]' is for element within array
#    @quick_add_companies[0,0] = [['-- N/A --',0], ["-- New Company --", -2],['', -1]]
    
    # Prep pagination attributes
    @data_attributes_h[:user_id] = session[:user].id.to_s
    
    begin
      
      # Pagination logic - total no. of records
      @sql_s = "select count(id) count " + 
        "from role_applications " +
        "where person_id = " + @data_attributes_h[:user_id].to_s
  
      @results_count = RoleApplication.find_by_sql(@sql_s)
      raise 'Error while retrieving inbox messages!' if !@results_count || !@results_count[0]
      @data_attributes_h[:results_count] = @results_count[0].count
        
      @role_applications = RoleApplication.find_by_sql("SELECT " + 
          "RA.id application_id, " +
          "RA.updated_at application_updated_at, " +
          "R.close_date role_close_date, " +
          "R.title role_title, " +
          "RA.status_id application_status_id, " + 
          
          "O_Agency.name agency_name, " +
          "P_Agent.first_name agent_first_name, " +
          "P_Agent.last_name agent_last_name, " +
          "P_Agent.phone_work agent_work_phone, " +
          "P_Agent.mobile agent_mobile, " +
          
          "O_Company.name company_name, " +
          "P_Company_Contact.first_name company_contact_first_name, " +
          "P_Company_Contact.last_name company_contact_last_name, " +
          "P_Company_Contact.phone_work company_contact_work_phone, " +
          "P_Company_Contact.mobile company_contact_mobile " +
        "from " +
          "role_applications RA " +
          "JOIN roles R " +
          "LEFT JOIN organisations O_Company ON (O_Company.id = R.company_id) " +
          "LEFT JOIN organisations O_Agency ON (O_Agency.id = R.agency_id) " +
          "LEFT JOIN people P_Agent ON (P_Agent.id = R.agent_id) " +
          "LEFT JOIN people P_Company_Contact ON (P_Company_Contact.id = R.company_contact_id) " +        
        "where " +
          "R.id = RA.role_id and " +
          "RA.person_id = " + @data_attributes_h[:user_id].to_s + " " + 
        "order by " + @order_by + " " + @order_dir + " " + 
          
          "LIMIT " + @data_attributes_h[:starting_record].to_s + ", " + @data_attributes_h[:results_per_page].to_s)
        
      @results_h = {:pagination_info => @data_attributes_h }
          
    rescue Exception => exc
      print "***** ERROR: " + exc
    end
  end
  
 #
  # VIEW APPLICATIONS
  #

  def view_agent_home
    
    render 'agent/view_agent_home.html', :layout => 'agent_main_layout'
    
  end


  #
  # VIEW APPLICATIONS
  #
  def view_applications
    
    @quick_add_role_application = RoleApplication.new
    @quick_add_role_application.status_id = 1
    
    @quick_add_role = Role.new
    
    # Populate data for viewing all applications
    prep_view_applications
    
    render 'view_applications.html', :layout => 'role_application'
  end

  #
  # EDIT APPLICATION [MAIN]
  #
  def edit_application
    populate_application_summary params[:application_id]
    
    @role_application = RoleApplication.find(params[:application_id])
    @role = @role_application.role
    
    session[:mode] = 2
    session[:mode_action] = :update_application
    session[:mode_label] = "Update"   
    
    session[:page] = "main"
    
    # Clear the notification buffers
    flash[:error] = nil
    flash[:notice] = nil
    
    render 'edit_application.html', :layout => 'role_application'
  end
  
  def view_application
    
    populate_application_summary params[:application_id]
    
    @role_application = RoleApplication.find(params[:application_id])
    @role = @role_application.role
    
    session[:mode] = 2
    session[:mode_action] = :view_application
    session[:mode_label] = "View"   
    
    session[:page] = "main"
    
    # Clear the notification buffers
    flash[:error] = nil
    flash[:notice] = nil
    
    render 'view_application.html', :layout => 'role_application'
  end
  

  
#
  # EDIT APPLICATION [AGENCY]
  #
 
  
#
  # EDIT APPLICATION [AGENCY]
  #
 
  
#
  # EDIT APPLICATION [AGENCY]
  #
  def view_application_agency
    populate_application_summary params[:application_id]
      
    @agency = Organisation.find_by_sql("SELECT " + 
          "O_Agency.* " +
        "from " +
          "role_applications RA, " +
          "roles R, " +
          "organisations O_Agency " +
        "where " +
          "R.id = RA.role_id and " +
          "O_Agency.id = R.agency_id and " +
          "RA.id = " + params[:application_id].to_s)
          
      @agent = Person.find_by_sql("SELECT " +
          "P_Agent.* " +
        "from " +
          "role_applications RA, " +
          "roles R, " +
          "people P_Agent " +
        "where " +
          "R.id = RA.role_id and " +
          "P_Agent.id = R.agent_id and " +
          "RA.id = " + params[:application_id].to_s)
    
    if @agency && @agency[0]
      @agency = @agency[0]
    else
      @agency = Organisation.new
    end
    
    if @agent && @agent[0]
      @agent = @agent[0]
    else
      @agent = Person.new
    end
    
    render 'view_application_agency.html', :layout => 'role_application'
  end  
  
#
  # EDIT APPLICATION [AGENCY]
  #
  def edit_application_agency
    
    populate_application_summary params[:application_id]
      
    # If an agency was selected in the previous screen (not necessarily was 'clicked')
    if params[:agencies] && params[:agencies] != "-1"
        
      # Get the Agency details
      @agency = Organisation.find_by_sql("SELECT " + 
          "O_Agency.* " +
        "from " +
          "organisations O_Agency " +
        "where " +
          "O_Agency.id = " + params[:agencies].to_s)[0]
          
      # Select Agents for the Agency
      @agents = Person.find_by_sql("SELECT " +
          "P_Agent.* " +
        "from " +
          "people P_Agent " +
        "where " +
          "P_Agent.organisation_id = " + @agency.id.to_s)
      
      # If the user 'clicked' on an agency, populate Agent details
      if params[:pa] == "agency"
        
        # If it has agents
        if @agents && @agents[0]
          @agent = @agents[0]
        else
          @agent = Person.new
        end
      
      # Otherwise, if clicked on the 'agent' list
      elsif params[:pa] == "agent"
      
        if params[:agents]
          @agent = Organisation.find_by_sql("SELECT " + 
              "P_Agent.* " +
            "from " +
              "people P_Agent " +
            "where " +
              "P_Agent.id = " + params[:agents].to_s)[0]
        else
          @agent = Person.new
        end
      
      end
          
    # Otherwise, if there is a default agency
    else
      
      @role = Role.find_by_sql("SELECT " + 
          "roles.* " +
        "from roles, role_applications " + 
          "where role_applications.role_id = roles.id " + 
          "and role_applications.id = " + params[:application_id])[0]
      
      if @role.agency_id
      
        # Apparently the "find_by_sql" method returns an array of objects so if there's only one,
        # then the '[0]' index should be used
        @agency = Organisation.find_by_sql("SELECT " + 
            "O_Agency.* " +
          "from " +
            "role_applications RA, " +
            "roles R, " +
            "organisations O_Agency " +
          "where " +
            "R.id = RA.role_id and " +
            "O_Agency.id = R.agency_id and " +
            "RA.id = " + params[:application_id].to_s)[0]
            
        # Select Agents for the Agency
        @agents = Person.find_by_sql("SELECT " +
            "P_Agent.id, " +
            "P_Agent.first_name, " +
            "P_Agent.last_name " +
          "from " +
            "people P_Agent " +
          "where " +
            "P_Agent.organisation_id = " + @agency.id.to_s)
            
        @agent = Person.find_by_sql("SELECT " +
            "P_Agent.* " +
          "from " +
            "role_applications RA, " +
            "roles R, " +
            "people P_Agent " +
          "where " +
            "R.id = RA.role_id and " +
            "P_Agent.id = R.agent_id and " +
            "RA.id = " + params[:application_id].to_s)[0]
            
        @application_id = params[:application_id]
        
        @agent = Person.new if !@agent
      
      # 3) Otherwise, create a blank Agency
      else
        @agency = Organisation.new
        @agent = Person.new
      end
      
    end

    # Always show the list of agencies
    @agencies = Organisation.find_by_sql("SELECT " +
        "O_Agency.id, " +
        "O_Agency.name " +
      "from " +
        "person_to_organisations PTO, " +
        "organisations O_Agency " +
      "where " +
        "O_Agency.type_id = 1 and " + # 1 = Agency
        "O_Agency.id = PTO.organisation_id and " +
        "PTO.person_id = " + session[:user].id.to_s)        
        
    @application_id = params[:application_id]
    
    render 'edit_application_agency.html', :layout => 'role_application'
  end
  
  #
  # UPDATE CANDIDATE
  #
  def update_application_agency
    respond_to do |format|
      
      #TODO:Add data fields check and ask to confirm after clicking 'cancel'
      if params[:cancel]
        
        format.html { redirect_to :action => :view_application_agency, 
          :controller => :role_applications, 
          :application_id => params[:application_id] }
          
      else
        # Check if application has an agency and agent associated with it
        @role = Role.find_by_sql("SELECT " + 
            "roles.* " +
          "from roles, role_applications " + 
            "where role_applications.role_id = roles.id " + 
            "and role_applications.id = " + params[:application_id])[0]
        
        Role.transaction do
          begin
            if params[:agencies] && params[:agencies] != "-1" # If user selected an Agency from the list
              @role.update_attribute(:agency_id, params[:agencies])
              
              # Add a link to the link table
              # First check if the link exists
              @person_to_agency = PersonToOrganisation.find_by_person_id_and_organisation_id(
                session[:user].id, 
                params[:agencies])
                
              # if the link doesn't exist, create it
              if !@person_to_agency
                @person_to_agency = PersonToOrganisation.new
                @person_to_agency.person_id = session[:user].id
                @person_to_agency.organisation_id = params[:agencies]
                @person_to_agency.save!
              end     
            end
            
            if params[:agents] && params[:agents] != "-1" # If user selected an Agent from the list
              @role.update_attribute(:agent_id, params[:agents])
              
            # Otherwise, remove the agent from the 
            else
              @role.update_attribute(:agent_id, nil)
            end
          
            @role.save!
            
            flash[:notice] = 'Agency & Agent details were successfully updated.'
            flash[:error] = nil
              
            if params[:update] # If chose to just update the form, return to the edit screen
              
              format.html { redirect_to :action => :view_application_agency, 
                :controller => :role_applications, 
                :application_id => params[:application_id] }
                
            elsif params[:update_close]
              
              format.html { redirect_to :action => :view_applications, 
                :controller => :role_applications }
            end
            
            # AJAX code
            # 'inline' paramter returns a URL string to as a 'request' object to javascript on the client
            # This is a starting point for replacing HTML on the client
            format.js { render :inline => url_for(:controller => :role_applications, :action => :view_applications) }          
          rescue Exception => exc
            flash[:error] = exc.message
            
            puts exc.message
            
            @application_id = params[:application_id]
            
            populate_application_summary params[:application_id]
            
            format.html { render 'edit_application_agency.html', :layout => 'role_application' }
            #format.xml  { render :xml => @person.errors, :status => :unprocessable_entity }          
          end 
        end
      end
    end
  end
#
  # EDIT APPLICATION [COMPANY]
  #
  def view_application_company
    
      populate_application_summary params[:application_id]
    
      # Apparently the "find_by_sql" method returns an array of objects so if there's only one,
      # then the '[0]' index should be used
      @company = Organisation.find_by_sql("SELECT " + 
          "O_Company.* " +
        "from " +
          "role_applications RA, " +
          "roles R, " +
          "organisations O_Company " +
        "where " +
          "R.id = RA.role_id and " +
          "O_Company.id = R.company_id and " +
          "RA.id = " + params[:application_id].to_s)
          
      @company_contact = Person.find_by_sql("SELECT " +
          "P_Company_Contact.* " +
        "from " +
          "role_applications RA, " +
          "roles R, " +
          "people P_Company_Contact " +
        "where " +
          "R.id = RA.role_id and " +
          "P_Company_Contact.id = R.company_contact_id and " +
          "RA.id = " + params[:application_id].to_s)
          
    if @company && @company[0]
      @company = @company[0]
    else
      @company = Organisation.new
    end
    
    if @company_contact && @company_contact[0]
      @company_contact = @company_contact[0]
    else
      @company_contact = Person.new
    end
    
    session[:page] = "company"
    
    # Clear the notification buffers
    flash[:error] = nil
    flash[:notice] = nil    
    
    render 'view_application_company.html', :layout => 'role_application'
  end
  
#
  # EDIT APPLICATION [COMPANY]
  #
  def edit_application_company
    
    populate_application_summary params[:application_id]
    
    # If an company was selected in the previous screen (not necessarily was 'clicked')
    if params[:companies] && params[:companies] != "-1"
        
      # Get the company details
      @company = Organisation.find_by_sql("SELECT " + 
          "O_company.* " +
        "from " +
          "organisations O_company " +
        "where " +
          "O_company.id = " + params[:companies].to_s)[0]
          
      # Select company_contacts for the company
      @company_contacts = Person.find_by_sql("SELECT " +
          "P_company_contact.* " +
        "from " +
          "people P_company_contact " +
        "where " +
          "P_company_contact.organisation_id = " + @company.id.to_s)
      
      # If the user 'clicked' on an company, populate company_contact details
      if params[:pa] == "company"
        
        # If it has company_contacts
        if @company_contacts && @company_contacts[0]
          @company_contact = @company_contacts[0]
        else
          @company_contact = Person.new
        end
      
      # Otherwise, if clicked on the 'company_contact' list
      elsif params[:pa] == "company_contact"
      
        if params[:company_contacts]
          @company_contact = Organisation.find_by_sql("SELECT " + 
              "P_company_contact.* " +
            "from " +
              "people P_company_contact " +
            "where " +
              "P_company_contact.id = " + params[:company_contacts].to_s)[0]
        else
          @company_contact = Person.new
        end
      
      end
          
    # Otherwise, if there is a default company
    else
      
      @role = Role.find_by_sql("SELECT " + 
          "roles.* " +
        "from roles, role_applications " + 
          "where role_applications.role_id = roles.id " + 
          "and role_applications.id = " + params[:application_id])[0]
      
      if @role.company_id
      
        # Apparently the "find_by_sql" method returns an array of objects so if there's only one,
        # then the '[0]' index should be used
        @company = Organisation.find_by_sql("SELECT " + 
            "O_company.* " +
          "from " +
            "role_applications RA, " +
            "roles R, " +
            "organisations O_company " +
          "where " +
            "R.id = RA.role_id and " +
            "O_company.id = R.company_id and " +
            "RA.id = " + params[:application_id].to_s)[0]
            
        # Select company_contacts for the company
        @company_contacts = Person.find_by_sql("SELECT " +
            "P_company_contact.id, " +
            "P_company_contact.first_name, " +
            "P_company_contact.last_name " +
          "from " +
            "people P_company_contact " +
          "where " +
            "P_company_contact.organisation_id = " + @company.id.to_s)
            
        @company_contact = Person.find_by_sql("SELECT " +
            "P_company_contact.* " +
          "from " +
            "role_applications RA, " +
            "roles R, " +
            "people P_company_contact " +
          "where " +
            "R.id = RA.role_id and " +
            "P_company_contact.id = R.company_contact_id and " +
            "RA.id = " + params[:application_id].to_s)[0]
            
        @application_id = params[:application_id]
        
        @company_contact = Person.new if !@company_contact
      
      # 3) Otherwise, create a blank company
      else
        @company = Organisation.new
        @company_contact = Person.new
      end
      
    end
    
    # Always show the list of companies
    @companies = Organisation.find_by_sql("SELECT " +
        "O_Company.id, " +
        "O_Company.name " +
      "from " +
        "person_to_organisations PTO, " +
        "organisations O_Company " +
      "where " +
        "O_Company.type_id = 2 and " + # 1 = Agency
        "O_Company.id = PTO.organisation_id and " +
        "PTO.person_id = " + session[:user].id.to_s)
        
    @application_id = params[:application_id]  
    
    session[:page] = "company"
    
    # Clear the notification buffers
    flash[:error] = nil
    flash[:notice] = nil    
    
    render 'edit_application_company.html', :layout => 'role_application'
  end
  
  #
  # UPDATE APPLICATION COMPANY
  #
  def update_company
    
    @role_application = RoleApplication.find(params[:application_id])
    @role = @role_application.role

    respond_to do |format|
      Role.transaction do
        begin
          # DB Updates
          if params[:company]
            if !@role.company_id
              @company = Organisation.new(params[:company])
              @company.status_id = 1
              @company.type_id = 2
              @company.save!            
            else
              @company.update_attributes(params[:company])  
            end
            
            @role.company_id = @company.id
            
            # Only if there is a Company assigned, try and store the Comapny Contact information
            if params[:company_contact]
              if !@role.company_contact_id
                @company_contact = Person.new(params[:company_contact])
                @company_contact.status_id = 1
                @company_contact.person_type_id = 3
                @company_contact.organisation_id = @company.id
                @company_contact.save!            
              else
                @company_contact.update_attributes(params[:company_contact])  
              end
              
              @role.company_contact_id = @company_contact.id
            end            
          end
          
          @role.save!
          
          flash[:notice] = 'Company & Company Contact details were successfully updated.'
          flash[:error] = nil
          
          session.delete :company_id
          session.delete :company_contact_id

          format.html { redirect_to :action => :view_applications, 
            :controller => :role_applications, 
            :application_id => params[:application_id] }
          
          # AJAX code
          # 'inline' paramter returns a URL string to as a 'request' object to javascript on the client
          # This is a starting point for replacing HTML on the client
          format.js { render :inline => url_for(:controller => :role_applications, :action => :view_applications) }          
        rescue Exception => exc
          flash[:error] = exc.message
          
          @application_id = params[:application_id]
          
          format.html { render 'edit_application_company.html', :layout => 'role_application' }
          #format.xml  { render :xml => @person.errors, :status => :unprocessable_entity }          
        end
      end      
    end
  end    
  
  #
  # UPDATE APPLICATION COMPANY
  #
  def update_application_company
    
    respond_to do |format|
      
      #TODO:Add data fields check and ask to confirm after clicking 'cancel'
      if params[:cancel]
        format.html { redirect_to :action => :view_application_company, 
          :controller => :role_applications, 
          :application_id => params[:application_id] }
          
      else
        # Check if application has an agency and agent associated with it
        @role = Role.find_by_sql("SELECT " + 
            "roles.* " +
          "from roles, role_applications " + 
            "where role_applications.role_id = roles.id " + 
            "and role_applications.id = " + params[:application_id])[0]
        
        Role.transaction do
          begin
            if params[:companies] && params[:companies] != "-1" # If user selected an Agency from the list
              @role.update_attribute(:company_id, params[:companies])
              
              # Add a link to the link table
              # First check if the link exists
              @person_to_company = PersonToOrganisation.find_by_person_id_and_organisation_id(
                session[:user].id, 
                params[:companies])
                
              # if the link doesn't exist, create it
              if !@person_to_company
                @person_to_company = PersonToOrganisation.new
                @person_to_company.person_id = session[:user].id
                @person_to_company.organisation_id = params[:companies]
                @person_to_company.save!
              end
            end
            
            if params[:company_contacts] && params[:company_contacts] != "-1" # If user selected an Agent from the list
              @role.update_attribute(:company_contact_id, params[:company_contacts])
              
            # Otherwise, remove the agent from the 
            else
              @role.update_attribute(:company_contact_id, nil)
            end
          
            @role.save!
            
            flash[:notice] = 'Company & Company Contact details were successfully updated.'
            flash[:error] = nil
              
            if params[:update] # If chose to just update the form, return to the edit screen
              
              format.html { redirect_to :action => :view_application_company, 
                :controller => :role_applications, 
                :application_id => params[:application_id] }
                
            elsif params[:update_close]
              
              format.html { redirect_to :action => :view_applications, 
                :controller => :role_applications }
                
            end
            
            # AJAX code
            # 'inline' paramter returns a URL string to as a 'request' object to javascript on the client
            # This is a starting point for replacing HTML on the client
            format.js { render :inline => url_for(:controller => :role_applications, :action => :view_applications) }          
          rescue Exception => exc
            flash[:error] = exc.message
            
            @application_id = params[:application_id]
            
            populate_application_summary params[:application_id] 
            
            format.html { render 'edit_application_company.html', :layout => 'role_application' }
            #format.xml  { render :xml => @person.errors, :status => :unprocessable_entity }          
          end 
        end
      end
    end
    
  end    
  
#
  # EDIT APPLICATION [MESSAGES]
  #
  def edit_application_messages
    @person = Person.find(session[:person_id])
    @role_application = @person.role_application.find(params[:application_id])
    @role = @role_application.role    
    
    # Clear the notification buffers
    flash[:error] = nil
    flash[:notice] = nil
    
    session[:page] = "messages"
    
    render 'edit_messages.html', :layout => 'role_application'
  end
  
    #
  # ADD CANDIDATE
  #


  #
  # ADD CANDIDATE
  #
  def add_application
    # AP: Need to put Person in session once the user has logged in 
    @person = session[:user]
    @role_application = RoleApplication.new
    @role = Role.new
    
    session[:mode] = 1
    session[:mode_action] = :create_application
    session[:mode_label] = "Create"
    
    session[:page] = "main"
    
    @role_application.id = 0
    
    render 'edit_application.html', :layout => 'role_application'
  end
  
  def new_job
    @person = session[:user]
    
    @role_application = RoleApplication.new
    @role_application.status_id = 1
    
    @role = Role.new
    
    @role_application.id = 0
    @is_new = true
    
    render 'edit_application.html', :layout => 'role_application'
  end
  
  #
  # CREATE CANDIDATE
  #

  
  #
  # CREATE CANDIDATE
  #
  def create_application_quick
    
    @quick_add_agency = Organisation.new(params[:quick_add_agency])
    @quick_add_company = Organisation.new(params[:quick_add_company])
    
    # 'Role'
    ## 1. Agency
    ## 2. Company
    @quick_add_role = Role.new(params[:quick_add_role])
    
    # 'RoleApplication'
    ## 1. Title
    ## 2. Status
    ## 3. Closing date
    @quick_add_role_application = RoleApplication.new(params[:quick_add_role_application])
    @quick_add_role_application.role = @quick_add_role
    @quick_add_role_application.person = session[:user]

    respond_to do |format|
      RoleApplication.transaction do
        begin
          failed_validation = false
          
          # CHECK Validation
          ## AGENCY
          if @quick_add_role.agency_id == -2
            @quick_add_agency.status_id = 1
            @quick_add_agency.type_id = 1
            
            failed_validation = true if !@quick_add_agency.valid?
          end
          
          ## COMPANY
          if @quick_add_role.company_id == -2
            @quick_add_company.status_id = 1
            @quick_add_company.type_id = 2
            
            failed_validation = true if !@quick_add_company.valid?
          end
          
          ## ROLE and ROLE_APPLICATION
          failed_validation = true if !@quick_add_role_application.valid?
          failed_validation = true if !@quick_add_role.valid?
          
          raise 'ERRORS: ' + @quick_add_role.errors.to_xml if failed_validation
          
          # SAVE Everything
          if @quick_add_role.agency_id == -2
            @quick_add_agency.save(false)
            @quick_add_role.agency_id = @quick_add_agency.id
            
            # Create a new entry for PersonToOrganisation only when a new Agency is selected
            @quick_add_person_to_agency = PersonToOrganisation.new(:person_id => session[:user].id, :organisation_id => @quick_add_role.agency_id)
            @quick_add_person_to_agency.save(false)
          end
          
          if @quick_add_role.company_id == -2
            @quick_add_company.save(false)
            @quick_add_role.company_id = @quick_add_company.id
            
            # Create a new entry for PersonToOrganisation only when a new Company is selected
            @quick_add_person_to_company = PersonToOrganisation.new(:person_id => session[:user].id, :organisation_id => @quick_add_role.company_id)
            @quick_add_person_to_company.save(false)
          end
          
          @quick_add_role.agency_id = nil if @quick_add_role.agency_id == 0
          @quick_add_role.company_id = nil if @quick_add_role.company_id == 0
          
          @quick_add_role_application.save(false)
          @quick_add_role.save(false)
          
          flash[:notice] = 'Application was successfully created.'
        
          # Reset the error queue
          flash[:error] = nil
          
          # Continue to edit the application, continue to 
          if params[:add]
            
            format.html { redirect_to :action => :view_applications, 
              :controller => :role_applications }
              
          elsif params[:add_edit]
            
            format.html { redirect_to :action => :edit_application, 
              :controller => :role_applications, 
              :application_id => @quick_add_role_application.id }
              
          end
            
          format.js { render :inline => url_for(:controller => :role_applications, :action => params[:next]) }
          
        rescue Exception => exc
          
          puts "xxxxx: " + exc.message
          
          flash[:error] = 'Errors were found in the fields below, please check the messages next to each field'
          
          prep_view_applications
          
          format.html { render 'view_applications.html', :layout => 'role_application' }
          
        end     
      end
    end
  end
  
  def save_application
    
    @is_new = true
    
    flash[:notice] = flash[:error] = nil
    
    respond_to do |format|
      
      #TODO:Add data fields check and ask to confirm after clicking 'cancel'
      if params[:cancel]
        
        format.html { redirect_to :action => :view_applications, 
          :controller => :role_applications }
          
      else
        
        @role = Role.new(params[:role])
        @role_application = RoleApplication.new(params[:role_application])
        @custom_type = CustomType.new(params[:custom_type])
        
        @custom_type.select_id = -3
        
        @role_application.role = @role
        @role_application.person = session[:user]
    
        Role.transaction do
          
          begin
            
            failed_validation = false
            
            failed_validation = true if !@role.valid?
            failed_validation = true if !@role_application.valid?
            failed_validation = true if (@role.source_id == -2 && !@custom_type.valid?)
            
            raise 'ERROR' if failed_validation
            
            # 1. Save the 'Other' Source if selected
            if @role.source_id == -2
              @custom_type_find = CustomType.find(:last, :conditions => [ "user_id = ? AND type_id = ?", session[:user].id.to_s, 1.to_s])
              
              @custom_type.select_id = @custom_type_find.select_id - 1 if @custom_type_find
              @custom_type.type_id = 1 # Source
              @custom_type.user_id = session[:user].id
              @custom_type.save(false)
              
              @role.source_id = @custom_type.select_id
            end
            
            @role.save(false)
            @role_application.save(false)
            
            flash[:notice] = 'Job was successfully created.'
            flash[:error] = nil
  
            # Redirect back to the same page
            if params[:update] # If chose to just update the form, return to the edit screen
              
              format.html { redirect_to :action => :view_application, 
                :controller => :role_applications, 
                :application_id => @role_application.id }
                
            elsif params[:update_close]
              
              prep_view_applications
              
              format.html { redirect_to :action => :view_applications, 
                :controller => :role_applications }
                
            end
            
            format.js { render :inline => url_for(:controller => :role_applications, :action => params[:next]) }
            
          rescue Exception => exc
            
            flash[:error] = 'Errors were found in the fields below, please check the messages next to each field'
            
            format.html { render 'edit_application.html', :layout => 'role_application'  }          
          end # rescue
        end # transaction
        
      end # else      
    end # respond_to
    
  end

  #
  # UPDATE CANDIDATE
  #
  def update_application
    respond_to do |format|
      #TODO:Add data fields check and ask to confirm after clicking 'cancel'
      if params[:cancel]
        
        format.html { redirect_to :action => :view_application, 
          :controller => :role_applications, 
          :application_id => params[:application_id] }
          
      else
        @role_application = RoleApplication.find_by_id(params[:application_id])
        
        # Create objects with request attributes
        @role_application_param = RoleApplication.new(params[:role_application])
        @role_param = Role.new(params[:role])
        @custom_type_param = CustomType.new(params[:custom_type])
        
        @custom_type_param.select_id = -3
        @role_hash_params = params[:role]
    
        Role.transaction do
          
          begin
            failed_validation = false
            
            failed_validation = true if !@role_param.valid?
            failed_validation = true if !@role_application_param.valid?
            failed_validation = true if (@role_param.source_id == -2 && !@custom_type_param.valid?)
            
            raise 'ERROR' if failed_validation
            
            # 1. Save the 'Other' Source if selected
            if @role_param.source_id == -2
              @custom_type = CustomType.find(:last, :conditions => [ "user_id = ? AND type_id = ?", session[:user].id.to_s, 1.to_s])
              
              @custom_type_param.select_id = @custom_type.select_id - 1 if @custom_type
              @custom_type_param.type_id = 1 # Source
              @custom_type_param.user_id = session[:user].id
              @custom_type_param.save(false)
              
              @role_hash_params = @role_hash_params.update({"source_id" => @custom_type_param.select_id})
            end
            
            @role_application.update_attributes!(params[:role_application])
            @role_application.role.update_attributes!(@role_hash_params)
            
            flash[:notice] = 'Job was successfully updated.'
            flash[:error] = nil
  
            # Redirect back to the same page
            if params[:update] # If chose to just update the form, return to the edit screen
              
              format.html { redirect_to :action => :view_application, 
                :controller => :role_applications, 
                :application_id => params[:application_id] }
                
            elsif params[:update_close]
              
              format.html { redirect_to :action => :view_applications, 
                :controller => :role_applications  }
                
            end
            
            # AJAX code
            # 'inline' paramter returns a URL string to as a 'request' object to javascript on the client
            # This is a starting point for replacing HTML on the client
            format.js { render :inline => url_for(:controller => :role_applications, :action => params[:next]) }
            
          rescue Exception => exc
            @role = @role_param
            @role_application = @role_application_param
            @custom_type = @custom_type_param
            
            flash[:error] = 'Errors were found in the fields below, please check the messages next to each field'
            
            populate_application_summary params[:application_id] 
            
            format.html { render 'edit_application.html', :layout => 'role_application' }
            #format.xml  { render :xml => @person.errors, :status => :unprocessable_entity }          
          end # rescue
        end # transaction
      end # else      
    end # respond_to
  end
  
  #
  # REMOVE CANDIDATE
  #
  def delete_job
    @role_application = RoleApplication.find(params[:application_id])
    
    #puts "XXXX: " + @role_application.status_id.to_s if @role_application.status_id 
    #puts "XXXX: " + @role_application.role.title if @role_application.role 
    #puts "XXXX: " + @role_application.notes[0].note_contents if (@role_application.notes && @role_application.notes[0])
    
    @role_application.destroy
    @role_application.role.destroy
    @role_application.notes.destroy_all
    
    flash[:notice] = 'Job was successfully deleted!'
    flash[:error] = nil

    respond_to do |format|
      format.html { redirect_to :view_applications }
      format.xml  { head :ok }
    end
  end
  
  #
  # EDIT APPLICATION STATUS
  #
  def edit_application_status
    @person = Person.find(session[:person_id])
    @role_application = @person.role_application.find(params[:application_id])
    
    session[:mode] = 2
    session[:mode_action] = :update_application
    session[:mode_label] = "Update"
    session[:page] = "edit_application_status"
    
    # Clear the notification buffers
    flash[:error] = nil
    flash[:notice] = nil
    
    render 'edit_application_status.html', :layout => 'role_application'
  end
  
  #
  # UPDATE APPLICATION STATUS
  #
  def update_application_status
    #@person = Person.find(session[:person_id])
    @role_application = RoleApplication.find(params[:application_id])

    respond_to do |format|
      @role_application.transaction do
        begin
          @role_application.update_attributes!(params[:role_application])
          
          flash[:notice] = 'Application was successfully updated.'
          flash[:error] = nil
          
          if params[:note] && params[:note][:note_contents] && !params[:note][:note_contents].empty?
            @note = Note.new(params[:note])
            @note.role_application = @role_application
            @note.save!
          end
          
          # This should be the redirect after 'Update and Close' button
          #format.html { redirect_to :action => :view_applications }

          # Redirect back to the same page
          #format.html { render params[:page] + '.html', :layout => 'role_application' }
          
          # Continue to edit the application, continue to 
          format.html { redirect_to :action => :view_applications, 
            :controller => :role_applications}          
          
          # AJAX code
          # 'inline' paramter returns a URL string to as a 'request' object to javascript on the client
          # This is a starting point for replacing HTML on the client
          format.js { render :inline => url_for(:controller => :role_applications, :action => params[:next]) }          
        rescue Exception => exc
          flash[:error] = exc.message
          
          format.html { render params[:page] + '.html' }
          #format.xml  { render :xml => @person.errors, :status => :unprocessable_entity }          
        end
      end      
    end
  end
end
