class MyMailer < ActionMailer::Base
  
  def new_message_message(message_h, attributes_h, sent_at = Time.now)
    blank_message(message_h, attributes_h)
  end
  
  def action_missing_message(message_h, attributes_h, sent_at = Time.now)
    blank_message(message_h, attributes_h)
  end
  
  def blank_message(message_h, attributes_h, sent_at = Time.now)
    @from = message_h["sender"]
    @recipients = message_h["recipients"]
    @subject = message_h["subject"]
    @reply_to = message_h["reply_to"]
    @sent_on = sent_at
    @headers = {}
    
    @body = attributes_h if attributes_h
  end
  
  def init(message_h, attributes_h, template_s, sent_at = Time.now)
    
    @from = message_h["sender"]
    @recipients = message_h["recipients"]
    @subject = message_h["subject"]
    @reply_to = message_h["reply_to"]
    @sent_on = sent_at
    @headers = {}
    
    # Need to ensure the following template exists in the 'views/my_mailer' folder:
    # 'new_message_message.text.html.erb'.
    part :content_type => "text/html", 
      :body => email_header + render_message(template_s, attributes_h) + email_footer
    
    # This line requires the following file to exist in the above folder as well:
    # 'new_message_message.text.plain.erb'
#    part :content_type => "text/plain", :body => render_message(template_s, attributes_h)
  end
  
  def email_header
    '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
       "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">

    <html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
      <head>
          <meta http-equiv="content-type" content="text/html;charset=UTF-8" />
      </head>
    <body>'
  end
  
  def email_footer
    '</body>
    </html>'
  end
  
  #
  # This method will send messages using the 'external' daemon
  #
  def self.send_message_delayed(metadata_params_h, body_params_h, is_reply, type = 0, exchange_type = 0)
    
    # System email addresses
    @system_email_address = "system@flyc.co.nz"
    @admin_email_address = "admin@flyc.co.nz"
    @member_email_address = "member@flyc.co.nz"
    @no_reply_email_address = "no-reply@flyc.co.nz"
    
    # System user IDs
    @system_user_id = 0
    
    # System sender names
    @system_sender_name = "Flyc System"
    
    # if the message involves the 'admin' (either as sender or recipient)
    # Find the 'admin' user in the database so its user_id and names can be used in the email notification
    if exchange_type == 1 || exchange_type == 2 || exchange_type == 4 || exchange_type == 7 
      # Find the admin user in the database first
      @admin_user = Person.find(:first, :conditions => {:person_type_id => 0, :primary_email => "admin@flyc.co.nz"})
    end
    
    metadata_params_h = Hash.new if !metadata_params_h 
    
    if !is_reply
      if type == 1 # contact_us
        metadata_params_h[:subject] = "'Contact Us' message."
      elsif type == 3 # action missing
        metadata_params_h[:subject] = "'Action Missing' notification."
      elsif type == 7 # feedback
        metadata_params_h[:subject] = "'Feedback' message."
      end
    end
    
    if exchange_type == 1 # user to admin
      
      metadata_params_h[:sender_email] = @member_email_address
      
      metadata_params_h[:recipients] = Array.new(1, Hash.new)
      metadata_params_h[:recipients][0][:id] = @admin_user.id
      metadata_params_h[:recipients][0][:email] = @admin_email_address
      metadata_params_h[:recipients][0][:name] = @admin_user.first_name + " " + @admin_user.last_name 
      
    elsif exchange_type == 2 # admin to user
      
      metadata_params_h[:sender_id] = @admin_user.id
      metadata_params_h[:sender_email] = @admin_email_address
      metadata_params_h[:sender_reply_to_email] = @admin_email_address
      metadata_params_h[:sender_name] = @admin_user.first_name + " " + @admin_user.last_name 
#      metadata_params_h[:sender_name] = "Flyc Admin"
    
    elsif exchange_type == 4 # system to admin
      
      metadata_params_h[:sender_id] = @system_user_id
      metadata_params_h[:sender_email] = @system_email_address
      metadata_params_h[:sender_reply_to_email] = @no_reply_email_address
      metadata_params_h[:sender_name] = @system_sender_name
      
      metadata_params_h[:recipients] = Array.new(1, Hash.new)
      metadata_params_h[:recipients][0][:id] = @admin_user.id
      metadata_params_h[:recipients][0][:email] = @admin_email_address
      metadata_params_h[:recipients][0][:name] = @admin_user.first_name + " " + @admin_user.last_name 
    
    elsif exchange_type == 5 # system to user
      
      metadata_params_h[:sender_id] = @system_user_id
      metadata_params_h[:sender_email] = @system_email_address
      metadata_params_h[:sender_reply_to_email] = @no_reply_email_address
      metadata_params_h[:sender_name] = @system_sender_name
      
    elsif exchange_type == 7 # user to system (currently only 'Feedback' message)
      
      metadata_params_h[:recipients] = Array.new(1, Hash.new)
      metadata_params_h[:recipients][0][:id] = @admin_user.id
      metadata_params_h[:recipients][0][:email] = @admin_email_address
      metadata_params_h[:recipients][0][:name] = @admin_user.first_name + " " + @admin_user.last_name 
      
    end
    
    begin
      
      @my_messages_h = Hash.new if exchange_type == 4 || exchange_type == 5
      
      if exchange_type == 4 || exchange_type == 5
      
        # If this is a 'System message'
        # First, construct the 'email' message
        # Iterate through all recipients
        metadata_params_h[:recipients].each do |recipient|
          
          # 1. Create the messages's Metadata information as a Hash
          @message_h = Hash.new
          @message_h["sender"] = '"' + metadata_params_h[:sender_name] + '"' + ' <' + metadata_params_h[:sender_email] + '>'
          @message_h["reply_to"] = '"' + metadata_params_h[:sender_name] + '" ' + '<' + metadata_params_h[:sender_reply_to_email] + '>'
          @message_h["recipients"] = '"' + recipient[:name] + '" <' + recipient[:email] + '>'
          @message_h["subject"] = metadata_params_h[:subject]
          
          # 2. Construct the core 'body' attributes for the message as a Hash
#          body_params_h["redirection_key"] = @action.email_action_key 
          body_params_h["person_name"] = recipient[:name]
          
          # 3. Create the message object
          case type
            
            when 1 # contact us
            when 2 # system_notification
            when 3 # action missing
            
              my_message = create_action_missing_message(@message_h, body_params_h)
              
            when 4 # forgot password
            when 5 # registration confirmed
            when 6 # general message
            when 7 # feedback
       
          end
     
          metadata_params_h[:message_body] = my_message.body if !metadata_params_h[:message_body]  
          
          @my_messages_h[recipient[:email]] = my_message
        
        end      
       
      end
      
      # *********************************
      # 1 - STORE MESSAGE IN DATABASE ***
      # *********************************
    
      # Create the 'MyMailerMessage' object with the full HTML message
      @message = MyMailerMessage.new(:message_html => metadata_params_h[:message_body])
      
      # Store the message in the database
      failed_save = false
      failed_save = true if !@message.save
      raise 'ERRORS: ' + @message.errors.to_xml if failed_save
    
      # *****************************************************
      # 2 - CREATE 'METADATA' OBJECT WITH MESSAGE SUMMARY ***
      # *****************************************************

      # Strip HTML code from the message
      @body_plain = metadata_params_h[:message_body].gsub(/<(.|\n)*?>/, "").strip
      
      # Crop the first 80 characters as a summary for the message
      @body_plain_summary = @body_plain.gsub(/\s+/, " ")[0..80]
          
      @message_metadata = MyMailerMetadata.new
      
      # Set the message type (based on the 'type' provided to this method)
      @message_metadata.message_type_id = type
      
      # set the parent message id (in case this is a REPLY message)
      @message_metadata.parent_message_id = metadata_params_h[:parent_message_id] if is_reply
      
      # Sender is the current logged in user
      @message_metadata.sender_id = metadata_params_h[:sender_id] # System user
      
      # Set the message status for the 'sender' to 'Read'
      # Sent messages will automatically be flagged as sent
      @message_metadata.message_status_id = 2
      
      # Create the Recipients object and attach to the 'Message Metadata' record
      # Create 1 recipient (in this case the Admin) and set the 'message status' to 1 (Unread)
      metadata_params_h[:recipients].each do |recipient|
        @message_metadata.recipients.build(:attributes => {:recipient_id => recipient[:id], :message_status_id => 1})  
      end
      
      @message_metadata.subject = metadata_params_h[:subject]
      @message_metadata.message_summary = @body_plain_summary
      
      # Attach the 'message' object (already has its ID assigned (from step 1)
      @message_metadata.message = @message
      
      # Create a new 'Action' object and attach to the 'MetaData' object (assign the ID to it)
#      @message_metadata.build_action(:attributes => @action.attributes())
      
      # **********************************
      # 4 - SAVE THE 'METADATA' OBJECT ***
      # **********************************

      # 3. Save the message
      failed_save = false
      failed_save = true if !@message_metadata.save
      raise 'ERRORS: ' + @message_metadata.errors.to_xml if failed_save
      
      # Update the 'parent_message_id' to the same message_id in case this is a new message
      @message_metadata.update_attribute(:parent_message_id, @message_metadata.id) if !is_reply
      
      # **********************************
      # 3 - CREATE 'ACTION' REDIRECTOR *** [ FOR THE READER - ADMIN ]
      # ... I could add a 'send copy to myself' option and implement an action with the 'view_sent_message' option
      # **********************************

      # Create a friendly name of the this action
      # (In this case, the message's subject is the friendly name. This could be used on the site in a widget)
      # (Instead of dispaying the 'message_id' to the user (in the screen or an email), this will
      # be used as a better reference)
      @friendly_names_h2 = {"message_id" => @message_metadata.subject}
      
      case type
        
        when 1, 7 # contact us, feedback
        
          case exchange_type
            when 1 # user to admin
              @params_2 = {:controller => "admin_messages", :action => "admin_view_inbox_message"}
            when 2 # admin to user
              @params_2 = {:controller => "user_messages", :action => "view_inbox_message"}
          end
          
          @params_2["message_id"] = @message_metadata.id
          
        when 2 # system_notification
        when 3 # action missing - notifications 
        
#          @params_2 = {:controller => "admin_messages", :action => "admin_view_inbox_message"} 
        
        when 4 # forgot password
        when 5 # registration confirmed
        when 6 # general message
   
      end
      
      # *** Temporary, in case the message was not created by the system, create the 'action' object
      # *** In the future, some system notifications will have a link to the 'notification' page on the site
      if exchange_type != 4 && exchange_type != 5
        # Create the 'MailerAction' object
        @action = MyMailerAction::create_o(@params_2, @friendly_names_h2)
        
        # Create the unique key to be used in the email
        @action.email_action_key = Digest::MD5.hexdigest(metadata_params_h[:sender_reply_to_email] + Time.now.to_s)
        @action.my_mailer_metadata_id = @message_metadata.id
        
        failed_save = false
        failed_save = true if !@action.save
        raise 'ERRORS: ' + @action.errors.to_xml if failed_save
        
        # ******************************************************
        # 5 - SEND AN EMAIL NOTIFICATION FOR THE NEW MESSAGE *** [ TO THE ADMIN ]
        # ******************************************************
        
        # Iterate through all recipients
        metadata_params_h[:recipients].each do |recipient|
          
          # 1. Create the messages's Metadata information as a Hash
          @message_h = Hash.new
          @message_h["sender"] = '"' + metadata_params_h[:sender_name] + '"' + ' <' + metadata_params_h[:sender_email] + '>'
          @message_h["reply_to"] = '"' + metadata_params_h[:sender_name] + '" ' + '<' + metadata_params_h[:sender_reply_to_email] + '>'
          @message_h["recipients"] = '"' + recipient[:name] + '" <' + recipient[:email] + '>'
          @message_h["subject"] = @message_metadata.subject
          
          # 2. Construct the core 'body' attributes for the message as a Hash
          body_params_h["redirection_key"] = @action.email_action_key 
          body_params_h["person_name"] = recipient[:name]
          
          ######################################################
          ## CHANGES TO ENABLE DELAYED DELIVERY - START
          ######################################################
          
          # 3. Create the message object
          case type
            
            when 1, 7 # contact us, feedback
              
              # The method 'create_new_message_message' will call the 'new_message_message' method from this class
              # together with the 'template' 'new_messsage_message' html file located under 'views/my_mailer'
#              my_message = create_new_message_message(@message_h, body_params_h)
              
            when 2 # system_notification
            when 3 # action missing
            
#              my_message = create_action_missing_message(@message_h, body_params_h)
              
            when 4 # forgot password
            when 5 # registration confirmed
            when 6 # general message
       
          end
  
#          my_message.set_content_type 'text/html'
          
          # 4. Wrap the message with standard HTML code (header & footer)
          # Add header & footer
#          my_message.body = email_header + my_message.body + email_footer

          # 1. Construct the 'my_mailer_email' object
          # 2. Assign the attributes to it (based on TMail::Mail class which is created from the 'create_' of the ActionMailer)
          # 3. Save the 'my_mailer_email' object to the database
          # 4. Quit
          @mailer_email = MyMailerEmail.new
          @mailer_email.my_mailer_metadata_id = @message_metadata.id
          @mailer_email.headers = @message_h
          @mailer_email.body_attributes = body_params_h
          @mailer_email.template = "new_message_message" # for contact_us
          
          @mailer_email.save(false)
          
          # 5. Deliver the message
#          deliver my_message

          ######################################################
          ## CHANGES TO ENABLE DELAYED DELIVERY - FINISH
          ######################################################
        
        end
      end

      # If the message was generated by the system
      if exchange_type == 4 || exchange_type == 5
        
        @my_messages_h.each do |email_address, system_message|
          
          system_message.set_content_type 'text/html'
          
          # 4. Wrap the message with standard HTML code (header & footer)
          # Add header & footer
          system_message.body = email_header + system_message.body + email_footer
          
          deliver system_message
          
        end
      
      end
      
      # **************************
      # 6 - FINISH THE PROCESS ***
      # **************************
      
      return @message_metadata
      
    rescue Exception => exc

      return nil
      
    end    
  end
  
  #
  # TYPES
  # - 0 n/a (all fields required)
  # - 1 contact_us
  # - 2 system_notification
  # - 3 action missing (i.e. a page in the system doesn't have its metadata defined in the 'Activity' class
  # - 4 forgot password
  # - 5 registration confirmed
  # - 6 general message
  # - 7 feedback
  #
  # EXCHANGE_TYPES
  # - 0 n/a (all fields required)
  # - 1 user to admin
  # - 2 admin to user
  # - 3 user to user
  # - 4 system to admin
  # - 5 system to user
  #
  # This method creates db messages in the system between the various users (admin, system, users etc).
  # In addition, this method sends a 'templated' reminder to the recipients (one or more).
  # 
  # As part of sending the 'reminder email', the system will create the 3 core parameters which it will pass to
  # the 'MyMailer' component to use in the template.
  # The parameters are stored in the hash 'body_params_h'. Additional params can be added outside of this method.
  #
  # The following is the core list of parameters:
  #  1. :http_host  ->  holds the full host name to allow accurate email redirection (e.g. http://www.flyc.co.nz/, http://localhost:3002/ etc).
  #                     The value for this paramter is set at 'base_controller' with the 'send_message' method
  #  2. :redirection_key  ->  holds the key to redirect the user from the outside world to the appropriate action, controller and parameters
  #  3. :person_name  ->  holds the full name of the recipient (e.g. "Tomer Sagi", "Flyc Admin" etc)
  #     
  # Messages are split into 2 types:
  #  1. Content messages - These messages include content written by a user. These messages will have 1 message and 1 email which are
  #                        different from one another. The message will be stored in the database and will contain the content written
  #                        by the user. The email will be based on the 'template' indicating the user they have a new message
  #  2. System messages - These messages include messages fully generated by the system. Both message and email will be identical
  #
  def self.send_message(metadata_params_h, body_params_h, is_reply, type = 0, exchange_type = 0)
    
    # System email addresses
    @system_email_address = "system@flyc.co.nz"
    @admin_email_address = "admin@flyc.co.nz"
    @member_email_address = "member@flyc.co.nz"
    @no_reply_email_address = "no-reply@flyc.co.nz"
    
    # System user IDs
    @system_user_id = 0
    
    # System sender names
    @system_sender_name = "Flyc System"
    
    # if the message involves the 'admin' (either as sender or recipient)
    # Find the 'admin' user in the database so its user_id and names can be used in the email notification
    if exchange_type == 1 || exchange_type == 2 || exchange_type == 4 || exchange_type == 7 
      # Find the admin user in the database first
      @admin_user = Person.find(:first, :conditions => {:person_type_id => 0, :primary_email => "admin@flyc.co.nz"})
    end
    
    metadata_params_h = Hash.new if !metadata_params_h 
    
    if !is_reply
      if type == 1 # contact_us
        metadata_params_h[:subject] = "'Contact Us' message."
      elsif type == 3 # action missing
        metadata_params_h[:subject] = "'Action Missing' notification."
      elsif type == 7 # feedback
        metadata_params_h[:subject] = "'Feedback' message."
      end
    end
    
    if exchange_type == 1 # user to admin
      
      metadata_params_h[:sender_email] = @member_email_address
      
      metadata_params_h[:recipients] = Array.new(1, Hash.new)
      metadata_params_h[:recipients][0][:id] = @admin_user.id
      metadata_params_h[:recipients][0][:email] = @admin_email_address
      metadata_params_h[:recipients][0][:name] = @admin_user.first_name + " " + @admin_user.last_name 
      
    elsif exchange_type == 2 # admin to user
      
      metadata_params_h[:sender_id] = @admin_user.id
      metadata_params_h[:sender_email] = @admin_email_address
      metadata_params_h[:sender_reply_to_email] = @admin_email_address
      metadata_params_h[:sender_name] = @admin_user.first_name + " " + @admin_user.last_name 
#      metadata_params_h[:sender_name] = "Flyc Admin"
    
    elsif exchange_type == 4 # system to admin
      
      metadata_params_h[:sender_id] = @system_user_id
      metadata_params_h[:sender_email] = @system_email_address
      metadata_params_h[:sender_reply_to_email] = @no_reply_email_address
      metadata_params_h[:sender_name] = @system_sender_name
      
      metadata_params_h[:recipients] = Array.new(1, Hash.new)
      metadata_params_h[:recipients][0][:id] = @admin_user.id
      metadata_params_h[:recipients][0][:email] = @admin_email_address
      metadata_params_h[:recipients][0][:name] = @admin_user.first_name + " " + @admin_user.last_name 
    
    elsif exchange_type == 5 # system to user
      
      metadata_params_h[:sender_id] = @system_user_id
      metadata_params_h[:sender_email] = @system_email_address
      metadata_params_h[:sender_reply_to_email] = @no_reply_email_address
      metadata_params_h[:sender_name] = @system_sender_name
      
    elsif exchange_type == 7 # system to user
      
      metadata_params_h[:recipients] = Array.new(1, Hash.new)
      metadata_params_h[:recipients][0][:id] = @admin_user.id
      metadata_params_h[:recipients][0][:email] = @admin_email_address
      metadata_params_h[:recipients][0][:name] = @admin_user.first_name + " " + @admin_user.last_name 
      
    end
    
    begin
      
      @my_messages_h = Hash.new if exchange_type == 4 || exchange_type == 5
      
      if exchange_type == 4 || exchange_type == 5
      
        # If this is a 'System message'
        # First, construct the 'email' message
        # Iterate through all recipients
        metadata_params_h[:recipients].each do |recipient|
          
          # 1. Create the messages's Metadata information as a Hash
          @message_h = Hash.new
          @message_h["sender"] = '"' + metadata_params_h[:sender_name] + '"' + ' <' + metadata_params_h[:sender_email] + '>'
          @message_h["reply_to"] = '"' + metadata_params_h[:sender_name] + '" ' + '<' + metadata_params_h[:sender_reply_to_email] + '>'
          @message_h["recipients"] = '"' + recipient[:name] + '" <' + recipient[:email] + '>'
          @message_h["subject"] = metadata_params_h[:subject]
          
          # 2. Construct the core 'body' attributes for the message as a Hash
#          body_params_h["redirection_key"] = @action.email_action_key 
          body_params_h["person_name"] = recipient[:name]
          
          # 3. Create the message object
          case type
            
            when 1 # contact us
            when 2 # system_notification
            when 3 # action missing
            
              my_message = create_action_missing_message(@message_h, body_params_h)
              
            when 4 # forgot password
            when 5 # registration confirmed
            when 6 # general message
            when 7 # feedback
       
          end
     
          metadata_params_h[:message_body] = my_message.body if !metadata_params_h[:message_body]  
          
          @my_messages_h[recipient[:email]] = my_message
        
        end      
       
      end
      
      # *********************************
      # 1 - STORE MESSAGE IN DATABASE ***
      # *********************************
    
      # Create the 'MyMailerMessage' object with the full HTML message
      @message = MyMailerMessage.new(:message_html => metadata_params_h[:message_body])
      
      # Store the message in the database
      failed_save = false
      failed_save = true if !@message.save
      raise 'ERRORS: ' + @message.errors.to_xml if failed_save
    
      # *****************************************************
      # 2 - CREATE 'METADATA' OBJECT WITH MESSAGE SUMMARY ***
      # *****************************************************

      # Strip HTML code from the message
      @body_plain = metadata_params_h[:message_body].gsub(/<(.|\n)*?>/, "").strip
      
      # Crop the first 80 characters as a summary for the message
      @body_plain_summary = @body_plain.gsub(/\s+/, " ")[0..80]
          
      @message_metadata = MyMailerMetadata.new
      
      # Set the message type (based on the 'type' provided to this method)
      @message_metadata.message_type_id = type
      
      # set the parent message id (in case this is a REPLY message)
      @message_metadata.parent_message_id = metadata_params_h[:parent_message_id] if is_reply
      
      # Sender is the current logged in user
      @message_metadata.sender_id = metadata_params_h[:sender_id] # System user
      
      # Set the message status for the 'sender' to 'Read'
      # Sent messages will automatically be flagged as sent
      @message_metadata.message_status_id = 2
      
      # Create the Recipients object and attach to the 'Message Metadata' record
      # Create 1 recipient (in this case the Admin) and set the 'message status' to 1 (Unread)
      metadata_params_h[:recipients].each do |recipient|
        @message_metadata.recipients.build(:attributes => {:recipient_id => recipient[:id], :message_status_id => 1})  
      end
      
      @message_metadata.subject = metadata_params_h[:subject]
      @message_metadata.message_summary = @body_plain_summary
      
      # Attach the 'message' object (already has its ID assigned (from step 1)
      @message_metadata.message = @message
      
      # Create a new 'Action' object and attach to the 'MetaData' object (assign the ID to it)
#      @message_metadata.build_action(:attributes => @action.attributes())
      
      # **********************************
      # 4 - SAVE THE 'METADATA' OBJECT ***
      # **********************************

      # 3. Save the message
      failed_save = false
      failed_save = true if !@message_metadata.save
      raise 'ERRORS: ' + @message_metadata.errors.to_xml if failed_save
      
      # Update the 'parent_message_id' to the same message_id in case this is a new message
      @message_metadata.update_attribute(:parent_message_id, @message_metadata.id) if !is_reply
      
      # **********************************
      # 3 - CREATE 'ACTION' REDIRECTOR *** [ FOR THE READER - ADMIN ]
      # ... I could add a 'send copy to myself' option and implement an action with the 'view_sent_message' option
      # **********************************

      # Create a friendly name of the this action
      # (In this case, the message's subject is the friendly name. This could be used on the site in a widget)
      # (Instead of dispaying the 'message_id' to the user (in the screen or an email), this will
      # be used as a better reference)
      @friendly_names_h2 = {"message_id" => @message_metadata.subject}
      
      case type
        
        when 1, 7 # contact us, feedback
        
          case exchange_type
            when 1 # user to admin
              @params_2 = {:controller => "admin_messages", :action => "admin_view_inbox_message"}
            when 2 # admin to user
              @params_2 = {:controller => "user_messages", :action => "view_inbox_message"}
          end
          
          @params_2["message_id"] = @message_metadata.id
          
        when 2 # system_notification
        when 3 # action missing - notifications 
        
#          @params_2 = {:controller => "admin_messages", :action => "admin_view_inbox_message"} 
        
        when 4 # forgot password
        when 5 # registration confirmed
        when 6 # general message
   
      end
      
      # *** Temporary, in case the message was not created by the system, create the 'action' object
      # *** In the future, some system notifications will have a link to the 'notification' page on the site
      if exchange_type != 4 && exchange_type != 5
        # Create the 'MailerAction' object
        @action = MyMailerAction::create_o(@params_2, @friendly_names_h2)
        
        # Create the unique key to be used in the email
        @action.email_action_key = Digest::MD5.hexdigest(metadata_params_h[:sender_reply_to_email] + Time.now.to_s)
        @action.my_mailer_metadata_id = @message_metadata.id
        
        failed_save = false
        failed_save = true if !@action.save
        raise 'ERRORS: ' + @action.errors.to_xml if failed_save
        
        # ******************************************************
        # 5 - SEND AN EMAIL NOTIFICATION FOR THE NEW MESSAGE *** [ TO THE ADMIN ]
        # ******************************************************
        
        # Iterate through all recipients
        metadata_params_h[:recipients].each do |recipient|
          
          # 1. Create the messages's Metadata information as a Hash
          @message_h = Hash.new
          @message_h["sender"] = '"' + metadata_params_h[:sender_name] + '"' + ' <' + metadata_params_h[:sender_email] + '>'
          @message_h["reply_to"] = '"' + metadata_params_h[:sender_name] + '" ' + '<' + metadata_params_h[:sender_reply_to_email] + '>'
          @message_h["recipients"] = '"' + recipient[:name] + '" <' + recipient[:email] + '>'
          @message_h["subject"] = @message_metadata.subject
          
          # 2. Construct the core 'body' attributes for the message as a Hash
          body_params_h["redirection_key"] = @action.email_action_key 
          body_params_h["person_name"] = recipient[:name]
          
          # 3. Create the message object
          case type
            
            when 1, 7 # contact us, feedback
              
              # The method 'create_new_message_message' will call the 'new_message_message' method from this class
              # together with the 'template' 'new_messsage_message' html file located under 'views/my_mailer'
              my_message = create_new_message_message(@message_h, body_params_h)
              
            when 2 # system_notification
            when 3 # action missing
            
              my_message = create_action_missing_message(@message_h, body_params_h)
              
            when 4 # forgot password
            when 5 # registration confirmed
            when 6 # general message
       
          end
  
          my_message.set_content_type 'text/html'
          
          # 4. Wrap the message with standard HTML code (header & footer)
          # Add header & footer
          my_message.body = email_header + my_message.body + email_footer
          
          # 5. Deliver the message
          deliver my_message
        
        end
      end

      # If the message was generated by the system
      if exchange_type == 4 || exchange_type == 5
        
        @my_messages_h.each do |email_address, system_message|
          
          system_message.set_content_type 'text/html'
          
          # 4. Wrap the message with standard HTML code (header & footer)
          # Add header & footer
          system_message.body = email_header + system_message.body + email_footer
          
          deliver system_message
          
        end
      
      end
      
      # **************************
      # 6 - FINISH THE PROCESS ***
      # **************************
      
      return @message_metadata
      
    rescue Exception => exc

      return nil
      
    end      
  end

  def setup(message, sent_at = Time.now)
    @subject = message.subject
    @body['person_name'] = message.person_name
    @body['confirmation_email_key'] = message.confirmation_email_key
    @recipients = message.recipients
    @from = message.sender
    @sent_on = sent_at
    @headers = {}
  end
  
  def registration_confirmed(message, sent_at = Time.now)
    @subject = message.subject
    @body['person_name'] = message.person_name
    @recipients = message.recipients
    @from = message.sender
    @sent_on = sent_at
    @headers = {}
  end
  
  def forgot_password(message, sent_at = Time.now)
    @subject = message.subject
    @body['person_name'] = message.person_name
    @body['person_password'] = message.person_password
    @recipients = message.recipients
    @from = message.sender
    @sent_on = sent_at
    @headers = {}
  end
  
  def test_message(message_h, attributes_h, sent_at = Time.now)
    @from = message_h["sender"]
    @recipients = message_h["recipients"]
    @subject = message_h["subject"]
    
    #@body['person_name'] = message.person_name
    
    @reply_to = message_h["reply_to"]
    @sent_on = sent_at
    @headers = {}
  end
end
