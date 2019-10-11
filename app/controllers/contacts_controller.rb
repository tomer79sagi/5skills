class ContactsController < ApplicationController

  def delete_contact
    respond_to do |format|
      
      @contact = Person.find_by_id(params[:contact_id])
      @organisation_id = @contact.organisation_id  
      
      Person.transaction do
        begin
          
          # 1. Destroy the relationship between a Job Seeker and the Agent
          #TODO: After link between person to contacts is created, destroy the link here
          
          # 2. Destroy the Agent record
          @contact.destroy
          
          flash[:notice] = session[:organisation_contact_type_name] + " '" + @contact.first_name + " " + @contact.last_name + "' was deleted successfully!"
            
          format.html { redirect_to :action => :view_organisation_contacts, 
            :controller => :contacts, 
            :organisation_id => @organisation_id }
          
          format.js { render :inline => url_for(:controller => :role_applications, :action => params[:next]) }
          
        rescue Exception => exc
          
          flash[:error] = 'Errors were found in the fields below, please check the messages next to each field'
          
          populate_organisation_summary @organisation_id
          
          format.html { render 'view_organisation_contacts.html' }          
        end # rescue
      end # transaction
          
    end # respond_to
  end
  
  def new_organisation_contact
    populate_organisation_summary params[:organisation_id]
    
    @contact = Person.new
    @contact.first_name = ""
    @contact.last_name = ""
    
    session[:mode_label] = "Create"
    session[:page] = "new_organisation_contact"
    
    render 'new_organisation_contact.html', :layout => 'role_application'
  end
  
  def view_organisation_contacts
    
    populate_organisation_summary params[:organisation_id]
    
     # Select Agents for the Agency
      @contacts = Person.find_by_sql("SELECT " +
          "P_Agent.* " +
        "from " +
          "people P_Agent " +
        "where " +
          "P_Agent.organisation_id = " + params[:organisation_id].to_s + " " + 
        "order by " + 
          "P_Agent.first_name asc, " + 
          "P_Agent.last_name asc")
          
    # Agents exist for the organisation
    if @contacts
      # If Agent was selected from previous screen, display it's details
              
      if params[:contact_id] || params[:contacts] # From a 'Job' or from the 'Contacts' screen
        @sql = "SELECT " + 
              "P_Agent.* " +
            "from " +
              "people P_Agent " +
            "where " +
              "P_Agent.id = "
        
        if params[:contacts]
          @sql += params[:contacts].to_s
        elsif params[:contact_id]
          @sql += params[:contact_id].to_s
        end
      
        @contact = Person.find_by_sql(@sql)[0]
        
        # Populate the 'Friendly Name' hash
        @friendly_names_h["contact_id"] = @contact.first_name
          
      # Otherwise take first contact as default
      else
        @contact = @contacts[0]  
      end
    end
    
    render 'view_organisation_contacts.html', :layout => 'role_application'
  end  
  
  def update_contact
    respond_to do |format|
      @contact = Person.find_by_id(params[:contact_id])
      
      #TODO:Add data fields check and ask to confirm after clicking 'cancel'
      if params[:cancel]
        
        format.html { redirect_to :action => :view_organisation_contacts, 
          :controller => :contacts, 
          :organisation_id => @contact.organisation_id,
          :contact_id => params[:contact_id] }
          
      else
    
        Organisation.transaction do
          begin      
            @contact.update_attributes!(params[:contact])
            
            flash[:notice] = session[:organisation_contact_type_name] + " '" + @contact.first_name + " " + @contact.last_name + "' was successfully updated."
            flash[:error] = nil
  
            # Redirect back to the same page
            if params[:update] # If chose to just update the form, return to the edit screen
              
              format.html { redirect_to :action => :view_organisation_contacts, 
                :controller => :contacts, 
                :organisation_id => @contact.organisation_id,
                :contact_id => params[:contact_id] }
                
            elsif params[:update_close]
              
              format.html { redirect_to :action => :view_organisations, 
                :controller => :organisations  }
                
            end
            
            format.js { render :inline => url_for(:controller => :role_applications, :action => params[:next]) }          
          rescue Exception => exc
            flash[:error] = exc.message
            
            populate_organisation_summary params[:organisation_id]
            
            format.html { render '/contacts/edit_organisation_contact.html' }          
          end # rescue
        end # transaction
        
      end # else      
    end # respond_to
    
  end

  def edit_contact
      
      @contact = Person.find_by_sql("SELECT " +
            "P_Agent.* " +
          "from " +
            "people P_Agent " +
          "where " +
            "P_Agent.id = " + params[:contact_id].to_s)
            
    if @contact && @contact[0]
      @contact = @contact[0]
    else
      @contact = Person.new
    end          
    
    @friendly_names_h["contact_id"] = @contact.first_name
            
    # Locate organisation based on Agent_ID
    # An contact will be treated as a stand-alone contact which will allow future associations to multiple 
    # organisations etc
    populate_organisation_summary @contact.organisation_id 
    
    render '/contacts/edit_organisation_contact.html', :layout => 'role_application'
  end  
  
  def save_organisation_contact
    respond_to do |format|
      #TODO:Add data fields check and ask to confirm after clicking 'cancel'
      if params[:cancel]
        
        format.html { redirect_to :action => :view_organisation_contacts, 
          :controller => :contacts, 
          :organisation_id => params[:organisation_id] }
          
      else
    
        Person.transaction do
          begin
            # 1. Save the Agent information
            @contact = Person.new(params[:contact])
            @contact.status_id = 1 # Created
            @contact.person_type_id = session[:organisation_contact_type_id].to_f # Agent
            @contact.organisation_id = params[:organisation_id]
            @contact.save!
            
            # 2. Update the user association to the conctact
            if !PersonToOrganisation.exists?(:person_id => session[:user].id, :organisation_id => params[:organisation_id])
              @person_to_organisation = PersonToOrganisation.new
              @person_to_organisation.person_id = session[:user].id
              @person_to_organisation.organisation_id = params[:organisation_id]
              @person_to_organisation.save!
            end
            
            flash[:notice] = session[:organisation_contact_type_name] + " '" + @contact.first_name + " " + @contact.last_name + "' was successfully saved."
            flash[:error] = nil
  
            # Redirect back to the same page
            if params[:save] # If chose to just update the form, return to the edit screen
              format.html { redirect_to :action => :view_organisation_contacts, 
                :controller => :contacts, 
                :organisation_id => @contact.organisation_id,
                :pa => "contact",
                :contacts => @contact.id }
                
            elsif params[:save_close]
              
              format.html { redirect_to :action => :view_organisations, 
                :controller => :organisations }
                
            end
            
            format.js { render :inline => url_for(:controller => :role_applications, :action => params[:next]) }
            
          rescue Exception => exc
            
            flash[:error] = 'Errors were found in the fields below, please check the messages next to each field'
            
            populate_organisation_summary params[:organisation_id]
            
            format.html { render '/contacts/new_organisation_contact.html', :layout => 'role_application' }          
          end # rescue
        end # transaction
        
      end # else      
    end # respond_to
    
  end  
  
end