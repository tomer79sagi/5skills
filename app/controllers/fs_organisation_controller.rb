require 'image_size'
# require 'yaml'

class FsOrganisationController < FsLoginController
  
  def view_organisation_summary(organisation_id, a_file_types)
    prep_files(organisation_id, a_file_types)
    
    respond_to do |format|
      
      format.json {
        if organisation_id
          @arr = {
            :status => "200",
            :action => params[:action],
            :files => Hash.new
          }
          
          @upload_files.each do |file_key, file|
            @arr[:files][file_key] = {
              :id => file.id
            }

            if file.large_dimensions
              @arr[:files][file_key][:large_dimensions] = {
                :width => file.large_dimensions.split("x")[0], 
                :height => file.large_dimensions.split("x")[1]  
              }
            end
          end
        else
          @arr = {
            :status => "100",
            :action => params[:action],
            :error => {
              :code => 1,
              :message => "'organisation_id' is missing!"
            }
          }
        end
          
        render :json => @arr.to_json, :callback => params[:callback] 
      }
      
    end
  end
  
  
  
  def create_organization(hash_attirbutes = {}, type = Fs2Organisation::ORGANISATION_TYPES[:agnecy], save_it = false)
    temp_agency = Fs2Organisation.new(hash_attirbutes)
    temp_agency.organisation_type = type
    
    temp_agency.save(false) if save_it
    temp_agency
  end
  
  def create_agency(hash_attirbutes = {}, save_it = false)
    create_organization(hash_attributes, Fs2Organisation::ORGANISATION_TYPES[:agnecy], save_it)
  end
  
  def create_company(hash_attirbutes = {}, save_it = false)
    create_organization(hash_attributes, Fs2Organisation::ORGANISATION_TYPES[:company], save_it)
  end   
  
  
  
  # -- 
  #
  # Required fields:
  #  - params[:agency] => { :name => XX }
  #  - params[:agency_contact] => { :full_name => XX }
  #
  def save_agency_profile
    agency = agency_contact = nil
    
    if !get_param([:agency, :name]).blank?
      
      params[:job_attributes] = {} if params[:job_attributes].nil?
      
      temp_agency = Fs2Organisation.new(params[:agency])
      temp_agency.organisation_type = Fs2Organisation::ORGANISATION_TYPES[:agency]
      raise 'ERROR' if !temp_agency.valid?
        
      agency = Fs2Organisation.find(:first, 
        :conditions => [ "lower(name) = ? AND organisation_type = ?", 
        get_param([:agency, :name]).downcase, Fs2Organisation::ORGANISATION_TYPES[:agency]])
      
      # 2. if no ID exists, create a new one
      if agency.nil?
        temp_agency.save(false)
        agency = temp_agency
        params[:job_attributes][:agency_id] = temp_agency.id
      else
        agency.update_attributes(temp_agency.attributes)
        params[:job_attributes][:agency_id] = agency.id
      end
      
      session[:agency] = agency
      
      # 3. Search for agency contact ID (by name)
      if !get_param([:agency_contact, :full_name]).blank?
        temp_agency_contact = Fs2Contact.new(params[:agency_contact])
        temp_agency_contact.contact_type = Fs2Contact::CONTACT_TYPES[:agency]
        temp_agency_contact.organisation_id = agency.id
        
        # If the logged-in user is the recruitment_agent, update its details 
        if session[:user].user_type_id == Fs2User::USER_TYPES[:recruitment_agent]
          agency_contact = session[:person]
        else
          agency_contact = Fs2Contact.find(:first,
            :conditions => [ "organisation_id = ? AND contact_type = ? AND lower(full_name) = ?", 
            agency.id, Fs2Contact::CONTACT_TYPES[:agency], get_param([:agency_contact, :full_name]).downcase ])
        end
        
        if agency_contact.nil?
          temp_agency_contact.user_id = session[:user] if session[:user].user_type_id == Fs2User::USER_TYPES[:recruitment_agent]
          temp_agency_contact.save(false)
          agency_contact = temp_agency_contact
          params[:job_attributes][:agency_contact_id] = temp_agency_contact.id
        else          
          attributes_to_change = agency_contact.attributes.merge(temp_agency_contact.attributes) do |key, oldval, newval|
            if !newval.nil?; newval; else oldval; end
          end
          
          agency_contact.update_attributes(attributes_to_change)
          params[:job_attributes][:agency_contact_id] = agency_contact.id
        end
        
        session[:person] = agency_contact
      end
    end
    
    {:agency => agency, :agency_contact => agency_contact}
  end
  
  
  # -- 
  #
  # Required fields:
  #  - params[:company] => { :name => XX }
  #  - params[:company_contact] => { :full_name => XX }
  #  
  def save_company_profile
    company = company_contact = nil
    
    if !get_param([:company, :name]).blank?
      
      params[:job_attributes] = {} if params[:job_attributes].nil?
      
      temp_company = Fs2Organisation.new(params[:company])
      temp_company.organisation_type = Fs2Organisation::ORGANISATION_TYPES[:company]
      raise 'ERROR' if !temp_company.valid?
        
      company = Fs2Organisation.find(:first, 
        :conditions => [ "lower(name) = ? AND organisation_type = ?", 
        get_param([:company, :name]).downcase, Fs2Organisation::ORGANISATION_TYPES[:company]])
      
      # 2. if no ID exists, create a new one
      if company.nil?
        temp_company.save(false)
        company = temp_company
        params[:job_attributes][:company_id] = temp_company.id 
      else
        company.update_attributes(temp_company.attributes)
        params[:job_attributes][:company_id] = company.id
      end
      
      session[:company] = company
      
      # 3. Search for company contact ID (by name)
      if !get_param([:company_contact, :full_name]).blank?
        temp_company_contact = Fs2Contact.new(params[:company_contact])
        temp_company_contact.contact_type = Fs2Contact::CONTACT_TYPES[:company]
        temp_company_contact.organisation_id = company.id
        raise 'ERROR' if !temp_company_contact.valid?
        
        # If the logged-in user is the recruitment_agent, update its details 
        if session[:user].user_type_id == Fs2User::USER_TYPES[:hiring_manager]
          company_contact = session[:person]
        else
          company_contact = Fs2Contact.find(:first, 
            :conditions => [ "organisation_id = ? AND contact_type = ? AND lower(full_name) = ?", 
            company.id, Fs2Contact::CONTACT_TYPES[:company], get_param([:company_contact, :full_name]).downcase ])
        end
        
        if company_contact.nil?
          temp_company_contact.user_id = session[:user] if session[:user].user_type_id == Fs2User::USER_TYPES[:hiring_manager]
          temp_company_contact.save(false)
          company_contact = temp_company_contact 
          params[:job_attributes][:company_contact_id] = temp_company_contact.id
        else
          attributes_to_change = company_contact.attributes.merge(temp_company_contact.attributes) do |key, oldval, newval|
            if !newval.nil?; newval; else oldval; end
          end
          
          company_contact.update_attributes(attributes_to_change)
          params[:job_attributes][:company_contact_id] = company_contact.id
        end

        session[:person] = company_contact
      end
    end
    
    {:company => company, :company_contact => company_contact}
  end
  
  def view_company_summary
    view_organisation_summary(params[:organisation_id], [Fs2File::FILE_TYPES[:company_logo]])
  end
  
  def view_agency_summary
    view_organisation_summary(params[:organisation_id], [Fs2File::FILE_TYPES[:agency_logo]])
  end  
  
end
