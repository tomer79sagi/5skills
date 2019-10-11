##require 'auditlogger'
#
# This controller is shared with the 'Admin' user.
# This is safe to do as there are no 'unsafe' or unique methods that MUSTN'T be here.
# The 'login_required', 'login_from_cookie' and 'access_denied' methods are generic
# The only change that is applied is in the 'access_denied' method

class ApplicationController < LoginController
 
  before_filter :pagination_start
  
  # Update the notifications bar.
  # Exception: When a new message is read, an explicit call is made to update the notifications
  before_filter :notifications, :except => [:view_inbox_message, :home]
  
  def home
    
    # This is part of the Mongrel MySQL Timeout workaround (to be deployed on production server)
    # This must be changed to something else more suitable at a later stage
    #@person = Person.find(1)
    
    if session[:user]
      if session[:user].person_type_id == 0 # website role (e.g. admin)
        redirect_to :action => :admin_view_inbox_messages, :controller => :admin_messages
        return
      else
        redirect_to :action => :view_applications, :controller => :role_applications
        return  
      end
    end
    
    @person = Person.new
    
    render '/main/homepage.html', :layout => "homepage"
    
  end
  
  def prep_sorting_info(sort_mapping_h, default_sb = nil, default_sd = nil)
    return if !sort_mapping_h
    
    if params[:sb] && params[:sd]
      @sort_by = params[:sb]
      @order_by = sort_mapping_h[params[:sb]]
      
      if params[:sd] == "down"
        @order_dir = "desc"
        @sort_dir_icon = " &darr;"
        
        # Action to perform when the user clicks on the title next time
        @sort_dir = "up"
      elsif params[:sd] == "up"
        @order_dir = "asc"
        @sort_dir_icon = " &uarr;"
        
        # Action to perform when the user clicks on the title next time
        @sort_dir = "down"
      end
    elsif default_sb && default_sd# Default
      # Perform current sort and display arrow reflecting sort direction
      @sort_by = default_sb
      @order_by = sort_mapping_h[default_sb]
      
      if default_sd == "down"
        @order_dir = "desc"
        @sort_dir_icon = " &darr;"
        
        # Action to perform when the user clicks on the title next time
        @sort_dir = "up"
      elsif default_sd == "up"
        @order_dir = "asc"
        @sort_dir_icon = " &uarr;"
        
        # Action to perform when the user clicks on the title next time
        @sort_dir = "down"
      end
    end
  end
  
  def pagination_start
    params[:p] = 1 if !params[:p]
    @results_per_page = 10
    
    @data_attributes_h = { 
      :results_per_page => @results_per_page,
      :page_number => params[:p].to_s,
      :starting_record => (params[:p].to_i - 1) * @results_per_page } 
  end
  
  def prep_pagination_info(attributes_h)
    @pagination_info = Hash.new
    @pagination_info[:results_count] = attributes_h[:results_count].to_s
    
    @pagination_info[:starting_point] = ((attributes_h[:page_number].to_i - 1) * attributes_h[:results_per_page].to_i).to_s
    @pagination_info[:results_per_page] = attributes_h[:results_per_page].to_s
    
    # Calc no. of pages
    @pagination_info[:number_of_pages] = (attributes_h[:results_count].to_f / attributes_h[:results_per_page].to_f).ceil.to_s
    @pagination_info[:page_number] = attributes_h[:page_number].to_s
    
    @pagination_info[:previous_page] = 1
    @pagination_info[:previous_page] = (attributes_h[:page_number].to_i - 1) if attributes_h[:page_number].to_i > 1
    
    @pagination_info[:next_page] = @pagination_info[:number_of_pages].to_i
    @pagination_info[:next_page] = (attributes_h[:page_number].to_i + 1) if attributes_h[:page_number].to_i < @pagination_info[:number_of_pages].to_i
  end

  protected
  
    # Overloading the 'render' method to allow for smart pagination to complete
    def render(options = nil, extra_options = {}, &block)
      # your code goes here
      prep_pagination_info(@results_h[:pagination_info]) if @results_h && @results_h[:pagination_info]
  
      # call the ActionController::Base render to show the page
      super
    end
  
    def notifications
      return if params[:controller] == "bookmarklet"
      
      @new_messages = MyMailerRecipient.count(:conditions => "recipient_id = #{session[:user].id} AND message_status_id = 1")
    end
  
    def log
      ##log = AuditLogger.new('./log/custom.log')
      ##log.datetime_format = "%Y-%m-%d %H:%M:%S"
      #log.level = Logger::INFO
      
      ##log.info "___________________________________________________________________________"
      ##log.info "*** SESSION LOG ***"
      
      session.each do |key, value|
        ##log.debug " #{key} => #{value}"
      end
      
      ##log.info "*** REQUEST LOG ***"
      
      params.each do |key, value|
        ##log.debug " #{key} => #{value}"
      end
    end
  
  def populate_organisation_summary(organisation_id)
    @organisation_summary = Organisation.find_by_sql("SELECT " + 
          "O_Agency.id organisation_id, " +
          "O_Agency.name organisation_name, " +
          "O_Agency.phone organisation_phone, " +
          "O_Agency.fax organisation_fax, " +
          "O_Agency.type_id organisation_type " +
          
        "from " +
          "organisations O_Agency " +
          
        "where " +
          "O_Agency.id = " + organisation_id.to_s)
          
    if @organisation_summary && @organisation_summary[0]
      @organisation_summary = @organisation_summary[0]
    else
      @organisation_summary = Organisation.new
    end
    
    # Populate the 'Friendly Name' hash
    @friendly_names_h["organisation_id"] = @organisation_summary.organisation_name
    
    # Initialize organisation type
    if @organisation_summary.organisation_type == "1" # Agency
      
      session[:organisation_type_name] = "Agency"
      session[:organisation_type_name_plural] = "Agencies"
       
      session[:organisation_contact_type_name] = "Agent"
      session[:organisation_contact_type_name_plural] = "Agents"
       
      session[:organisation_type_id] = "1" # Agency
      session[:organisation_contact_type_id] = "2" # Agent
      
    elsif @organisation_summary.organisation_type == "2" # Company
      
      session[:organisation_type_name] = "Company" 
      session[:organisation_type_name_plural] = "Companies"
       
      session[:organisation_contact_type_name] = "Company Contact"
      session[:organisation_contact_type_name_plural] = "Company Contacts"
       
      session[:organisation_type_id] = "2" # Company
      session[:organisation_contact_type_id] = "3" # Company Contact
      
    end
  end

  def populate_application_summary(application_id)
    #TODO: Store in session only NECESSARY fields and not whole objects
    
    begin
        
      @application_summary = RoleApplication.find_by_sql("SELECT " + 
          "RA.id application_id, " +
          "RA.updated_at application_updated_at, " +
          "RA.status_id application_status_id, " +
          "count(N_Notes.id) notes_total, " +
          
          "R.close_date role_close_date, " +
          "R.title role_title, " + 
          "R.type_id role_type_id, " +
          "R.salary_min role_salary_min, " +
          "R.salary_max role_salary_max, " +
          "R.salary_frequency_id role_salary_type_id, " +
          "R.start_date role_start_date, " +
          "R.duration role_duration, " +
          "R.duration_type_id role_duration_type_id, " +
          
          "O_Agency.name agency_name, " +
          "P_Agent.id agent_id, " +
          "P_Agent.first_name agent_first_name, " +
          "P_Agent.last_name agent_last_name, " +
          "P_Agent.phone_work agent_phone_work, " +
          "P_Agent.mobile agent_mobile, " +
          
          "O_Company.name company_name, " +
          "P_Company_Contact.id company_primary_contact_id, " +
          "P_Company_Contact.first_name company_primary_contact_first_name, " +
          "P_Company_Contact.last_name company_primary_contact_last_name, " +
          "P_Company_Contact.phone_work company_primary_contact_phone_work, " +
          "P_Company_Contact.mobile company_primary_contact_mobile " +
        "from " +
          "role_applications RA " +
          "JOIN roles R " +
          "LEFT JOIN organisations O_Company ON (O_Company.id = R.company_id) " +
          "LEFT JOIN organisations O_Agency ON (O_Agency.id = R.agency_id) " +
          "LEFT JOIN people P_Agent ON (P_Agent.id = R.agent_id) " +
          "LEFT JOIN people P_Company_Contact ON (P_Company_Contact.id = R.company_contact_id) " +
          "LEFT JOIN notes N_Notes ON (RA.id = N_Notes.role_application_id) " +
        "where " +
          "R.id = RA.role_id and " +
          "RA.id = " + application_id)[0]
          
    rescue Exception => exc
      print "***** ERROR: " + exc
    end
    
  end
  
end
