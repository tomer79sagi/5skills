class AgenciesController < OrganisationsController

   before_filter :initialize_session
   
   def initialize_session
     session[:organisation_type_name] = "Agency"
     session[:organisation_type_name_plural] = "Agencies"
     
     session[:organisation_contact_type_name] = "Agent"
     session[:organisation_contact_type_name_plural] = "Agents"
     
     session[:organisation_type_id] = "1" # Agency
     session[:organisation_contact_type_id] = "2" # Agent
     
     session[:organisation_color] = "#8eefff" # Company Contact
     session[:organisation_color_dark] = "#8eddff" # Company Contact
     
     if !params[:organisation_id] && params[:agency_id]
       params[:organisation_id] = params[:agency_id]
     end
  end
  
end