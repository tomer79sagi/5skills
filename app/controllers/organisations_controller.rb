class OrganisationsController < ApplicationController

  def prep_view_organisations
    
    prep_sorting_info(Organisation::sort_mapping, "organisation_name", "up")
    
    # Prep pagination attributes
    @data_attributes_h[:user_id] = session[:user].id.to_s
    @data_attributes_h[:organisation_type_id] = session[:organisation_type_id]
    
    begin
      
      # Pagination logic - total no. of records
      @sql_s = "select count(o.id) count " + 
        "from organisations o, person_to_organisations pto " +
        "where pto.person_id = " + @data_attributes_h[:user_id].to_s + " and " + 
          "o.type_id = " + @data_attributes_h[:organisation_type_id] + " and " +
          "o.id = pto.organisation_id"
  
      @results_count = Organisation.find_by_sql(@sql_s)
      raise 'Error while retrieving inbox messages!' if !@results_count || !@results_count[0]
      @data_attributes_h[:results_count] = @results_count[0].count
      
      # Organisations query
      @sql_s = "select o.id organisation_id, o.name organisation_name " + 
        "from organisations o, person_to_organisations pto " +
        "where pto.person_id = " + @data_attributes_h[:user_id].to_s + " and " + 
          "o.type_id = " + @data_attributes_h[:organisation_type_id] + " and " +
          "o.id = pto.organisation_id"
      
      if @order_by == "organisation_name"
        @sql_s += " order by " + @order_by + " " + @order_dir
      end
      
      @sql_s += " LIMIT " + @data_attributes_h[:starting_record].to_s + ", " + @data_attributes_h[:results_per_page].to_s
          
      @organisations = Organisation.find_by_sql(@sql_s)
      
      # Query for the agents / company contacts based on the organisation IDs (which is already filtered)
      @sql_s = "select pp.organisation_id, " +
        "pp.id contact_id, " +
        "pp.first_name contact_first_name, " +
        "pp.last_name contact_last_name, " +
        "pp.phone_work contact_work_phone, " +
        "pp.mobile contact_mobile_phone, " +
        "pp.primary_email contact_email " +
        
        "from people pp " + 
        "where pp.organisation_id in (" + @organisations.collect {|x| x.organisation_id}.join(",") + ") " + 
        "order by pp.organisation_id, contact_first_name"
        
      @people = Person.find_by_sql(@sql_s)
      
      @people_to_organisations = Hash.new {|h,k| h[k] = []}
      @people.each { |person| @people_to_organisations[person.organisation_id] << person }
      
      @results_h = {:pagination_info => @data_attributes_h }
          
    rescue Exception => exc
      print "***** ERROR: " + exc
    end
  end
  
  def view_organisations
    
    # Populate data for viewing all applications
    prep_view_organisations
    
    render '/organisations/view_organisations.html', :layout => 'role_application'
  end

  def new_organisation
    # Create a blank organisation to display the summary
    @organisation_summary = Organisation.new
    
    @is_new = true
    
    render '/organisations/edit_organisation.html', :layout => 'role_application'
  end
  
  def delete_organisation
    respond_to do |format|
      
      @organisation = Organisation.find_by_id(params[:organisation_id])
      @organisation_name = @organisation.name
      
      Person.transaction do
        begin
          
          # 1. Locate all roles with reference to this organisation_id
          # Find all roles with 'organisation_id' of the organisation and 'contact_id' of contacts of the Agency
          @roles_as_agency = Role.find(:all, :conditions => {:agency_id => @organisation.id})
          @roles_as_company = Role.find(:all, :conditions => {:company_id => @organisation.id})
          
          @role_ids_as_agency = @roles_as_agency.collect {|role| role.id}
          @role_ids_as_company = @roles_as_company.collect {|role| role.id}
          
          Role.update_all({:agency_id => nil, :agent_id => nil}, :id => @role_ids_as_agency ) if @roles_as_agency
          Role.update_all({:company_id => nil, :company_contact_id => nil}, :id => @role_ids_as_company ) if @roles_as_company
          
          # 2. Remove person relationship to the Agency (PersonToOrganisation link)
          # Find all entries with 'organisation_id' of the organisation
          PersonToOrganisation.delete_all(:organisation_id => @organisation.id)
          
          # 3. Remove all contacts for the organisation
          # Find all Agents (people and 'type 2' with 'organisastion_id' of the organisation)
          Person.delete_all(:organisation_id => @organisation.id)
          
          # 4. Remove the organisation
          @organisation.destroy
          
          flash[:notice] = session[:organisation_type_name] + " '" + @organisation_name + "' and all its contacts was deleted successfully!"
            
          format.html { redirect_to :action => :view_organisations, 
            :controller => :organisations }
          
          format.js { render :inline => url_for(:controller => :role_applications, :action => params[:next]) }
          
        rescue Exception => exc
          
          flash[:error] = 'Errors were found in the fields below, please check the messages next to each field'
          flash[:error] = exc.message
          
          populate_organisation_summary @organisation.id
          
          format.html { render 'view_organisation.html', :layout => 'role_application' }        
        end # rescue
      end # transaction
          
    end # respond_to
  end  

  def update_organisation
    respond_to do |format|
      #TODO:Add data fields check and ask to confirm after clicking 'cancel'
      if params[:cancel]
        
        format.html { redirect_to :action => :view_organisation, 
          :controller => :organisations, 
          :organisation_id => params[:organisation_id] }
      else
    
        Organisation.transaction do
          begin
            
            if params[:organisation_id]
              @organisation = Organisation.find_by_id(params[:organisation_id])
              @organisation.update_attributes!(params[:organisation])
              
              # Add a link to the link table
              # First check if the link exists
              @person_to_organisation = PersonToOrganisation.find_by_person_id_and_organisation_id(
                session[:user].id, 
                @organisation.id)
                
              # if the link doesn't exist, create it
              if !@person_to_organisation
                @person_to_organisation = PersonToOrganisation.new
                @person_to_organisation.person_id = session[:person_id]
                @person_to_organisation.organisation_id = @organisation.id
                @person_to_organisation.save!
              end
              
              flash[:notice] = session[:organisation_type_name] + ' was successfully updated.'
              flash[:error] = nil
            end
  
            # Redirect back to the same page
            if params[:update] # If chose to just update the form, return to the edit screen
              
              format.html { redirect_to :action => :view_organisation, 
                :controller => :organisations, 
                :organisation_id => params[:organisation_id] }
                
            elsif params[:update_close]
              
              format.html { redirect_to :action => :view_organisations, 
                :controller => :organisations  }
                
            end
            
            # AJAX code
            # 'inline' paramter returns a URL string to as a 'request' object to javascript on the client
            # This is a starting point for replacing HTML on the client
            format.js { render :inline => url_for(:controller => :role_applications, :action => params[:next]) }          
          rescue Exception => exc
            flash[:error] = 'Errors were found in the fields below, please check the messages next to each field'
            
            populate_organisation_summary params[:organisation_id]
            
            format.html { render 'edit_organisation.html', :layout => 'role_application' }      
          end # rescue
        end # transaction
      end # else      
    end # respond_to
    
  end  
    
  def edit_organisation
    
    populate_organisation_summary params[:organisation_id]
      
    @organisation = Organisation.find_by_sql("SELECT " + 
          "O_Agency.* " +
        "from " +
          "organisations O_Agency " +
        "where " +
          "O_Agency.id = " + params[:organisation_id].to_s)
    
    if @organisation && @organisation[0]
      @organisation = @organisation[0]
    else
      @organisation = Organisation.new
    end
    
    render 'edit_organisation.html', :layout => 'role_application'
  end   
  
#
  # EDIT APPLICATION [AGENCY]
  #
  def view_organisation
    
    populate_organisation_summary params[:organisation_id]
      
    @organisation = Organisation.find_by_sql("SELECT " + 
          "O_Agency.* " +
        "from " +
          "organisations O_Agency " +
        "where " +
          "O_Agency.id = " + params[:organisation_id].to_s)
    
    if @organisation && @organisation[0]
      @organisation = @organisation[0]
    else
      @organisation = Organisation.new
    end
    
    render '/organisations/view_organisation.html', :layout => 'role_application'
  end   
  
  def create_organisation_quick
    
    @quick_add_organisation = Organisation.new(params[:quick_add_organisation])
    @quick_add_contact = Person.new(params[:quick_add_contact])
    
    respond_to do |format|
      Organisation.transaction do
        begin
          failed_validation = false
          
          # 1. CHECK Validation
          ## 1.1 AGENCY
          @quick_add_organisation.status_id = 1
          @quick_add_organisation.type_id = session[:organisation_type_id].to_f
          failed_validation = true if !@quick_add_organisation.valid?
          
          ## 1.2 AGENT
          @quick_add_contact.status_id = 1 # New
          @quick_add_contact.person_type_id = session[:organisation_contact_type_id].to_f # Agent          
          failed_validation = true if !@quick_add_contact.valid?
          
          raise 'ERROR' if failed_validation
          
          # 2. SAVE Everything

          ## 2.1 AGENCY
          
          @quick_add_organisation.save(false)
          
          ## 2.2 PERSON_TO_AGENCY

          # Create a new entry for PersonToOrganisation only when a new Agency is selected
          @quick_add_person_to_organisation = PersonToOrganisation.new(
            :person_id => session[:user].id, :organisation_id => @quick_add_organisation.id)
          @quick_add_person_to_organisation.save(false)
          
          ## 2.3 AGENT
          
          @quick_add_contact.organisation_id = @quick_add_organisation.id
          @quick_add_contact.save(false)
          
          flash[:notice] = session[:organisation_type_name] + ' was successfully created.'
        
          # Reset the error queue
          flash[:error] = nil
          
          # Continue to edit the application, continue to 
          if params[:add]
            
            format.html { redirect_to :action => :view_organisations, 
              :controller => :organisations }
              
          elsif params[:add_edit]
            
            format.html { redirect_to :action => :edit_organisation, 
              :controller => :organisations, 
              :organisation_id => @quick_add_organisation.id }
              
          end
            
          format.js { render :inline => url_for(:controller => :role_applications, :action => params[:next]) }
          
        rescue Exception => exc
          
          flash[:error] = 'Errors were found in the fields below, please check the messages next to each field'
          
          prep_view_organisations
          
          format.html { render '/organisations/view_organisations.html', :layout => 'role_application' }
          
        end     
      end
    end
  end  
  
  def save_organisation
    
    @is_new = true
    
    flash[:notice] = flash[:error] = nil
    
    respond_to do |format|
      
      #TODO:Add data fields check and ask to confirm after clicking 'cancel'
      if params[:cancel]
        
        format.html { redirect_to :action => :view_organisations, 
          :controller => :organisations }
          
      else
        
        @organisation = Organisation.new(params[:organisation])
    
        Organisation.transaction do
          
          begin
            
            failed_validation = false
            
            # 1. CHECK Validation
            ## 1.1 AGENCY
            
            @organisation.status_id = 1
            @organisation.type_id = session[:organisation_type_id].to_f
            
            failed_validation = true if !@organisation.valid?
            
            raise 'ERROR' if failed_validation
            
            # 2. SAVE Everything

            ## 2.1 AGENCY
            
            @organisation.save(false)
            
            ## 2.2 PERSON_TO_AGENCY
  
            # Create a new entry for PersonToOrganisation only when a new Agency is selected
            @person_to_organisation = PersonToOrganisation.new(
              :person_id => session[:user].id, :organisation_id => @organisation.id)
            @person_to_organisation.save(false)
            
            flash[:notice] = session[:organisation_type_name] + ' was successfully saved.'
            flash[:error] = nil
  
            # Redirect back to the same page
            if params[:update] # If chose to just update the form, return to the edit screen
              
              format.html { redirect_to :action => :view_organisation, 
                :controller => :organisations, 
                :organisation_id => @organisation.id }
                
            elsif params[:update_close]
              
              format.html { redirect_to :action => :view_organisations, 
                :controller => :organisations }
                
            end
            
            format.js { render :inline => url_for(:controller => :role_applications, :action => params[:next]) }
            
          rescue Exception => exc
            
            flash[:error] = 'Errors were found in the fields below, please check the messages next to each field'
            
            format.html { render '/organisations/edit_organisation.html', :layout => 'role_application'  }          
          end # rescue
        end # transaction
        
      end # else      
    end # respond_to
    
  end
  
end