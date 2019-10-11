# The 'login' controller will serve public pages that do not require authentication

class AccountController < BaseController
         
    def process_forgot_password
      if params[:login]['email'].empty?
        flash[:error] = "Please enter an email address."
        render 'forgot_password.html', :layout => "homepage"
      else
        @person = Person.find_by_primary_email(params[:login]['email'])
      
        if @person
          redirect_to :action => 'email_forgot_password', :controller => :messages, :person_id => @person.id
        else
          flash[:error] = "Couldn't find the email in the database, make sure you entered the right email address or perhaps you need to register."
          redirect_to :action => 'login', :username => params[:login]['email']
        end
      end      
    end
    
    def forgot_password
      render 'forgot_password.html', :layout => "homepage"
    end
    
    def forgot_password_email_sent
      render 'forgot_password_email_sent.html', :layout => "homepage"
    end
    
    def email_confirm_sent
      render 'email_confim_sent.html', :layout => "homepage"
    end
    
    def process_registration
      flash.clear
      flash[:action] = "register"
      @user_type = params["user_type"]
      
      failed_validation = false
      
      @person = Person.new(params[:person])
      @person.status_id = 2 # indicating a 'new' contact which is not verified yet
      
      failed_validation = true if !@person.valid?
      
      if params["user_type"].to_i == 2 || params["user_type"].to_i == 3
        @organisation = Organisation.new(params[:organisation])
        @organisation.status_id = 1 # indicating a 'quick' add of a company, bypassing the full validation
        @organisation.type_id = params["user_type"].to_i
        
        failed_validation = true if !@organisation.valid?
      end
      
      Person.transaction do
          
        begin    
          
          raise 'ERROR' if failed_validation
                    
          @organisation.save(false) if params["user_type"].to_i == 2 || params["user_type"].to_i == 3
          
          @person.organisation_id = @organisation.id
          @person.save(false)
          
          flash[:notice] = 'Job was successfully created.'
          flash[:error] = nil

          format.html { redirect_to :action => :view_applications, 
              :controller => :role_applications }
          
        rescue Exception => exc
          
          flash[:error] = 'Errors were found in the fields below, please check the messages next to each field'
          
          if params["user_type"].to_i == 1
            render '/main/homepage.html', :layout => "homepage"
          else
            render '/company_contact/organisation_registration.html', :layout => "homepage"
          end
          
        end # rescue
      end # transaction
  
#      respond_to do |format|
#        format.html do
#          
#          failed = false
#          
#          if @person.save
#            flash[:notice] = 'You have successfully registered!'
#            
#            # Send confirmation email
#            redirect_to :action => 'email_confirm', :controller => :my_mailer, :person_id => @person.id
#          else
#            failed = true
#          end
#          
#          if failed
#            flash[:error] = 'Errors were found in the fields below, please check the messages next to each field'
#            # flash[:notice] = 'Beta Password is incorrect. YESSSSS'
#            
#            render '/main/homepage.html', :layout => "homepage"
#          end
#        end
#        
#        # Still need testing of this part to make the Javascript validation work in real-time
#        #format.js { render :action => 'validate' }
#      end
    end

  #
  # This method is called when the user clicks on the "Confirm" link from their email
  #
  def process_registration_confirmation
    begin
      @email_confirmation = EmailConfirmation.find_by_confirmation_string(params[:confirmation_key])
      
      @person = Person.find(@email_confirmation.person_id)
      @person.update_attribute('status_id', 3) # Update to 'Verified'
      
      @email_confirmation.destroy # Once the user is verified, delete the 'unique' key from the database
    
      flash[:notice] = 'Registration confirmation successful.'
      
      # Send an email of successful registration
      redirect_to :action => :email_registration_confirmed, :controller => :messages, :person_id => @person.id
    
    rescue Exception => exc
      print exc.messag
      flash[:error] = "An error has occured, couldn't confirm your registration"
      redirect_to :action => :home, :controller => :application
    end
  end
  
  #
  # This method is called when the user clicks on the "Confirm" link from their email
  #
  def finish_registration_confirmation
    if 
      flash[:notice] = 'Registration confirmation successful.'
      render 'registration_confirmed.html', :layout => "homepage"
    else
      flash[:error] = "An error has occured, couldn't confirm your registration"
      redirect_to :action => :home, :controller => :application
    end
  end
end
