class CompaniesController < OrganisationsController

   before_filter :initialize_session
   
   def initialize_session
     session[:organisation_type_name] = "Company" 
     session[:organisation_type_name_plural] = "Companies"
     
     session[:organisation_contact_type_name] = "Company Contact"
     session[:organisation_contact_type_name_plural] = "Company Contacts"
     
     session[:organisation_type_id] = "2" # Company
     session[:organisation_contact_type_id] = "3" # Company Contact
     
     session[:organisation_color] = "#8eeff1" # Company Contact
     session[:organisation_color_dark] = "#8edff1" # Company Contact
     
     if !params[:organisation_id] && params[:company_id]
       params[:organisation_id] = params[:company_id]
     end
  end
  
end