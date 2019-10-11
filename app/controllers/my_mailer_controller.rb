#
# CONSTANTS DEFINTIONS
#
# Status:
#  1 - Read
#  2 - Unread
#  3 - Replied
#  4 - Archived
#  5 - Deleted
#

require 'digest'

class MyMailerController < BaseController
  
  def email_confirm
    @person = Person.find(params[:person_id])
    
    @message = Message.new
    @message.subject = "Registration Confirmation for '#{@person.first_name}'"
    @message.recipients = '"' + @person.first_name + ' ' + @person.last_name + '" ' + '<' + @person.primary_email + '>'
    @message.sender = '"Flyc Accounts" <accounts@flyc.co.nz>'
    
    @email_confirmation = EmailConfirmation.new
    @email_confirmation.person_id = @person.id
    @email_confirmation.confirmation_string = Digest::MD5.hexdigest(@person.primary_email + Time.now.to_s)
    
    @message.person_name = @person.first_name
    @message.confirmation_email_key = @email_confirmation.confirmation_string 
    
    my_message = MyMailer::create_setup(@message)
    my_message.set_content_type 'text/html'
    MyMailer::deliver my_message
    
    if @message.save && @email_confirmation.save
      flash[:notice] = 'Message was successfully created.'
      #redirect_to :action => :home, :controller => :main
      redirect_to :email_confirm_sent
    else
      flash[:error] = 'An error has occured.'
      render :action => :home, :controller => :main
    end
  end
  
  def email_registration_confirmed
    @person = Person.find(params[:person_id])
    
    @message = Message.new
    @message.subject = "Registration Confirmed for '#{@person.first_name}'"
    @message.recipients = '"' + @person.first_name + ' ' + @person.last_name + '" ' + '<' + @person.primary_email + '>'
    @message.sender = '"Flyc Accounts" <accounts@flyc.co.nz>'
    
    @message.person_name = @person.first_name
    
    my_message = MyMailer::create_registration_confirmed(@message)
    my_message.set_content_type 'text/html'
    MyMailer::deliver my_message
    
    if @message.save
      flash[:notice] = 'Message was successfully created.'
      redirect_to :action => :finish_registration_confirmation, :controller => :login
    else
      flash[:error] = 'An error has occured.'
      render :action => :login, :controller => :login
    end    
  end
  
  #
  # Send message from person to admin
  #  -1. Send email to system admin- DON'T NEED
  #  2. Store email in database
  #  3. Notify recipient (in this case, system admin = -1)
  #
  def send_contact_us_message
    
    begin
      
      # *********************************
      # 1 - STORE MESSAGE IN DATABASE ***
      # *********************************
    
      # Create the 'MyMailerMessage' object with the full HTML message
      @message = MyMailerMessage.new(:message_html => session[:temp])
      
      # Store the message in the database
      failed_save = false
      failed_save = true if !@message.save
      raise 'ERRORS: ' + @message.errors.to_xml if failed_save
    
      # *****************************************************
      # 2 - CREATE 'METADATA' OBJECT WITH MESSAGE SUMMARY ***
      # *****************************************************

      # Strip HTML code from the message
      @body_plain = session[:temp].gsub(/<(.|\n)*?>/, "").strip
      
      # Crop the first 80 characters as a summary for the message
      @body_plain_summary = @body_plain.gsub(/\s+/, " ")[0..80]
          
      @message_metadata = MyMailerMetadata.new
      
      # Sender is the current logged in user
      @message_metadata.sender_id = session[:user].id # System user
      
      # Set the message status for the 'sender' to 'Read'
      # Sent messages will automatically be flagged as sent
      @message_metadata.message_status_id = 2
      
      # Create the Recipients object and attach to the 'Message Metadata' record
      # Find the admin user in the database first
      @admin_user = Person.where(:person_type_id => 0, :primary_email => "admin@flyc.co.nz")
      
      # Create 1 recipient (in this case the Admin) and set the 'message status' to 1 (Unread)
      @message_metadata.recipients.build(:attributes => {
        :recipient_id => @admin_user.id,
        :message_status_id => 1})
      
      @message_metadata.subject = '''Contact Us'' message.'
      @message_metadata.message_summary = @body_plain_summary
      
      # Attach the 'message' object (already has its ID assigned (from step 1)
      @message_metadata.message = @message

      # **********************************
      # 3 - CREATE 'ACTION' REDIRECTOR *** [ FOR THE READER - ADMIN ]
      # ... I could add a 'send copy to myself' option and implement an action with the 'view_sent_message' option
      # **********************************

      # Create a friendly name of the this action
      # (In this case, the message's subject is the friendly name. This could be used on the site in a widget)
      # (Instead of dispaying the 'message_id' to the user (in the screen or an email), this will
      # be used as a better reference)
      @friendly_names_h2 = {"message_id" => @message_metadata.subject}
      
      # Construct the action parameters (controller, action and parameters)
      # ... This line will be used for a regular site user.
      #@params_2 = {:controller => "messages", :action => "view_inbox_message", "message_id" => @message.id}

      # ... This line will be used for the admin user
      @params_2 = {:controller => "admin_messages", :action => "view_inbox_message", "message_id" => @message.id}
      
      # Create the 'MailerAction' object
      @action = MyMailerAction::create_o(@params_2, @friendly_names_h2)
      
      # Create the unique key to be used in the email
      @action.email_action_key = Digest::MD5.hexdigest(session[:user].primary_email + Time.now.to_s)
      
      # Create a new 'Action' object and attach to the 'MetaData' object (assign the ID to it)
      @message_metadata.build_action(:attributes => @action.attributes())
      
      # **********************************
      # 4 - SAVE THE 'METADATA' OBJECT ***
      # **********************************

      # 3. Save the message
      failed_save = false
      failed_save = true if !@message_metadata.save
      raise 'ERRORS: ' + @message_metadata.errors.to_xml if failed_save 

      # ******************************************************
      # 5 - SEND AN EMAIL NOTIFICATION FOR THE NEW MESSAGE *** [ TO THE ADMIN ]
      # ******************************************************
    
      # 1. Create the messages's Metadata information as a Hash
      @message_h = Hash.new
      @message_h["sender"] = '"' + session[:user].first_name + ' ' + session[:user].last_name + '"' + ' <member@flyc.co.nz>'
      @message_h["reply_to"] = '"' + session[:user].first_name + ' ' + session[:user].last_name + '" ' + '<' + session[:user].primary_email + '>'
      @message_h["recipients"] = '"Flyc Admin" <admin@flyc.co.nz>'
      @message_h["subject"] = @message_metadata.subject
      
      # 2. Construct the 'body' attributes for the message as a Hash
      @attributes_h = create_mailer_attributes({"redirection_key" => @action.email_action_key}) 
      
      # 3. Create the message object
      my_message = MyMailer::create_new_message_message(@message_h, @attributes_h)
      my_message.set_content_type 'text/html'
      
      # 4. Wrap the message with standard HTML code (header & footer)
      # Add header & footer
      my_message.body = email_header + my_message.body + email_footer
      
      # 5. Deliver the message
      MyMailer::deliver my_message
      
      # **************************
      # 6 - FINISH THE PROCESS ***
      # **************************
    
      flash[:notice] = 'Message was successfully sent.'
      session[:temp] = nil
      
      redirect_to session[:exit_to_url]
      
    rescue Exception => exc
      
      flash[:error] = 'Couldn''t save message to DB: ' + exc.clean_backtrace.join( "\n" )
      redirect_to :action => :contact_us, :controller => :general
      
    end   
    
  end
  
  def process_email_action_key
    
    begin
        
      # Check if the 'action_key' in the email matches the 'action_key' in the database and also the 'recipient'
      @sql_s = "SELECT " + 
          "A.controller, " +
          "A.action, " +
          "A.parameter_ids, " +
          "A.parameter_names, " +
          "A.parameter_values " +
          
        "from " +
          "my_mailer_metadatas MD " +
          "JOIN my_mailer_actions A " +
          "LEFT JOIN my_mailer_recipients MR ON " + 
            "(MR.my_mailer_metadata_id = MD.id " +  
            "and MR.recipient_id = " + session[:user].id.to_s + ") " + 
          
        "where " +
          "A.my_mailer_metadata_id = MD.id and " +
          "A.email_action_key = '" + params[:email_action_key] + "'"
          
      @actions = MyMailerAction.find_by_sql(@sql_s)
      
      raise 'No Action Found for key ''' + 
        params[:email_action_key] + ''' and user ' + session[:user].id + '!' if !@actions || !@actions[0]
          
    rescue Exception => exc
      print "***** ERROR: " + exc
      redirect_to :action => :view_applications, :controller => :role_applications
    end
    
    puts " --- key: " + params[:email_action_key]
    puts " +++ Action: " + @actions[0].controller
    
    #@action = Action.find_all_by_email_action_key(@email_action_key)
    
    puts "SSS: " + ActivityFactory::to_link_to_options(@actions[0]).to_s
    
    #flash[:error] = 'Couldn''t save message to DB: ' + exc.clean_backtrace.join( "\n" )
    
    redirect_to(ActivityFactory::to_link_to_options(@actions[0]))

    #Activity.find_all_by_person_id(session[:user].id, :order => "created_at desc")
  end
  
  #
  # Send message from person to system
  #  1. Send email to system admin
  #  2. Store email in database
  #  3. Notify recipient (in this case, system admin = -1)
  #
  def test_message
    # 1. Construct the message's metadata
    @message_h = Hash.new
    @message_h["sender"] = '"Flyc Member" <member@flyc.co.nz>'
    @message_h["reply_to"] = '"' + session[:user].first_name + ' ' + session[:user].last_name + '" ' + '<' + session[:user].primary_email + '>'
    @message_h["recipients"] = '"Flyc Admin" <tomer@flyc.co.nz>'
    @message_h["subject"] = "Flyc says HELLO!!!!!!!!!"
    
    @attributes_h = Hash.new
    @attributes_h["name"] = "Tomer"
    
    # 2. Create the message object using 'my_mailer'
    my_message = MyMailer::create_test_message(@message_h, @attributes_h)
    my_message.set_content_type 'text/html'
    
    @body_plain = my_message.body.gsub(/<(.|\n)*?>/, "").strip
    @body_plain_summary = @body_plain.gsub(/\s+/, " ")[0..80]
        
    @message_metadata = MyMailerMetadata.new
    @message_metadata.sender_id = session[:user].id # System user
    @message_metadata.recipients.build(:attributes => {:recipient_id => 0})
    @message_metadata.subject = @message_h["subject"]
    @message_metadata.summary = @body_plain_summary
    @message_metadata.build_message(:attributes => {:message_html => my_message.body})

    # 3. Wrap the message with HTML code (header & footer)
    # Add header & footer
    my_message.body = email_header + my_message.body + email_footer
    
    # 4. Deliver the message
    MyMailer::deliver my_message
    
    # 5. Save the message
    if @message_metadata.save
      flash[:notice] = 'Message was successfully created.'
      redirect_to :action => :view_applications, :controller => :role_applications
    else
      flash[:error] = 'An error has occured.'
      render :action => :view_applications, :controller => :role_applications
    end
    
  end
  
  def email_forgot_password
    @person = Person.find(params[:person_id])
    
    @message = Message.new
    @message.subject = "Your Flyc Password"
    @message.recipients = '"' + @person.first_name + ' ' + @person.last_name + '" ' + '<' + @person.primary_email + '>'
    @message.sender = '"Flyc Accounts" <accounts@flyc.co.nz>'
    
    @message.person_name = @person.first_name
    @message.person_password = @person.password    
    
    my_message = MyMailer::create_forgot_password(@message)
    my_message.set_content_type 'text/html'
    MyMailer::deliver my_message
    
    if @message.save
      flash[:notice] = 'Message was successfully created.'
      redirect_to :action => :forgot_password_email_sent, :controller => :login
    else
      flash[:error] = 'An error has occured.'
      render :action => :login, :controller => :login
    end    
  end
end
