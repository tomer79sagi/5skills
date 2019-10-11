class MyMailerMetadata < ActiveRecord::Base
  
  has_one :message, :class_name => 'MyMailerMessage', :foreign_key => "my_mailer_metadata_id"
  has_one :action, :class_name => 'MyMailerAction', :foreign_key => "my_mailer_metadata_id"
  has_one :feedback, :class_name => 'Feedback', :foreign_key => "my_mailer_metadata_id"
  has_many :recipients, :class_name => 'MyMailerRecipient', :foreign_key => "my_mailer_metadata_id"
  has_one :email, :class_name => 'MyMailerEmail', :foreign_key => "my_mailer_metadata_id"
  
  # Statuses:
  #  1 - Unread
  #  2 - Read
  #  3 - Replied
  #  4 - Archived
  #  5 - Deleted
  #
  def self.message_statuses
      [['Unread', 1],
      ['Read', 2],
      ['Replied', 3], 
      ['Archived', 4],
      ['Deleted', 5]]
  end
  
  # Message types
  #
  # - 1 contact_us
  # - 2 system_notification
  # - 3 action missing (i.e. a page in the system doesn't have its metadata defined in the 'Activity' class
  # - 4 forgot password
  # - 5 registration confirmed
  # - 6 general message
  # - 7 feedback
  #
  def self.message_types
    [['Contact Us', 1],
    ['System Notification', 2], # General system notification
    ['System Notification', 3], # Action missing 
#    ['Forgot Password', 4],
#    ['Registration', 5],
    ['Message', 6],
    ['Feedback', 7]]
  end
  
  # def self.get_inbox_messages(recipient_id)
  # Attributes Hash is the same used for the 'pagination_info' method
  def self.get_inbox_messages(attributes_h = {}) 
  
    begin
      
      # Pagination logic - total no. of records
      @sql_s = "select count(distinct md.parent_message_id) count " + 
        "from my_mailer_metadatas md, my_mailer_recipients mr " + 
        "where mr.my_mailer_metadata_id = md.id " +
        "and mr.recipient_id = " + attributes_h[:recipient_id].to_s
  
      @results_count = MyMailerRecipient.find_by_sql(@sql_s)
      raise 'Error while retrieving inbox messages!' if !@results_count || !@results_count[0]
      attributes_h[:results_count] = @results_count[0].count
        
      @sql_s = "SELECT " + 
          "MD.id, " +
          "MD.subject, " +
          "MD.created_at, " +
          "MD.message_summary, " +
          "MR.message_status_id, " +
          "MD.message_type_id, " +
          "MD.sender_id, " +
          
          "MD_person.first_name sender_first_name, " +
          "MD_person.last_name sender_last_name, " +
          
          "md_max.last_id, " + 
          "md_max.parent_message_id, " +
          "md_max.updated_at l_message_updated_at, " +
          "md_max.message_summary l_message_summary, " + 
          "md_max.sender_id l_message_sender_id, " +
          
          "MP_md_max.first_name l_message_sender_first_name, " +
          "MP_md_max.last_name l_message_sender_last_name, " +

          "md_count.count, " +
          
          "MR.recipient_id, " + 
          "MP.first_name recipient_first_name, " +
          "MP.last_name recipient_last_name, " +
          "MO.id organisation_id, " +
          "MO.name organisation_name " +
          
        "FROM " +
          "my_mailer_metadatas MD " +
          "JOIN my_mailer_messages MM on (MM.my_mailer_metadata_id = MD.id) " + 
          "JOIN my_mailer_recipients MR on (MR.my_mailer_metadata_id = MD.id) " +
          
          "join " +
            "(select id, count(id) count, parent_message_id " +
            "from my_mailer_metadatas " +
            "group by parent_message_id) md_count on (md_count.parent_message_id = MD.parent_message_id) " +
            
          "LEFT JOIN people MD_person on (MD_person.id = MD.sender_id) " +
          "LEFT JOIN people MP on (MP.id = MR.recipient_id) " + 
          "LEFT JOIN organisations MO on (MO.id = MP.organisation_id) " + 
          
          "left join " + 
            "(select md3.id last_id, parent_message_id, message_summary, updated_at, sender_id " + 
            "from my_mailer_metadatas md3 " + 
            "where md3.id = " + 
            "(select max(id) " + 
            "from my_mailer_metadatas " + 
            "where parent_message_id = md3.parent_message_id)) " + 
            "md_max on (md_max.parent_message_id = MD.parent_message_id) " +
            
          "LEFT JOIN people MP_md_max on (MP_md_max.id = md_max.sender_id) " +
          
        "WHERE " +
          "MD.id = " + 
          "(select max(mmm.id) " + 
          "from my_mailer_metadatas mmm " +
          "join my_mailer_recipients recp on (recp.my_mailer_metadata_id = mmm.id) " + 
          "where mmm.parent_message_id = MD.parent_message_id and recp.recipient_id = " + attributes_h[:recipient_id].to_s + ") " +
          
        "ORDER BY " + 
          "MD.created_at DESC " + 
          
        "LIMIT " + attributes_h[:starting_record].to_s + ", " + attributes_h[:results_per_page].to_s
          
      @messages = MyMailerMetadata.find_by_sql(@sql_s)
      
      raise 'Error while retrieving inbox messages!' if !@messages
          
    rescue Exception => exc
      print "*** EXCEPTION [get_inbox_messages]: " + exc.message
      @messages = nil
    end
    
    {:collection => @messages, :pagination_info => attributes_h}
  end
  
  def self.get_sent_messages(attributes_h)
    
    begin
      
      # Pagination logic - total no. of records
      @sql_s = "select count(distinct md.parent_message_id) count " + 
        "from my_mailer_metadatas md " + 
        "where md.sender_id = " + attributes_h[:sender_id].to_s
  
      @results_count = MyMailerMetadata.find_by_sql(@sql_s)
      raise 'Error while retrieving inbox messages!' if !@results_count || !@results_count[0]
      attributes_h[:results_count] = @results_count[0].count
        
      @sql_s = "SELECT " + 
          "MD.id, " +
          "MD.subject, " +
          "MD.created_at, " +
          "MD.message_summary, " +
          "MR.message_status_id, " +
          "MD.message_type_id, " +
          "MD.sender_id, " +
          
          "MD_person.first_name sender_first_name, " +
          "MD_person.last_name sender_last_name, " +
          
          "md_max.last_id, " + 
          "md_max.parent_message_id, " +
          "md_max.updated_at l_message_updated_at, " +
          "md_max.message_summary l_message_summary, " + 
          "md_max.sender_id l_message_sender_id, " +
          
          "MP_md_max.first_name l_message_sender_first_name, " +
          "MP_md_max.last_name l_message_sender_last_name, " +

          "md_count.count, " +
          
          "MR.recipient_id, " + 
          "MP.first_name recipient_first_name, " +
          "MP.last_name recipient_last_name, " +
          "MO.id organisation_id, " +
          "MO.name organisation_name " +
          
        "FROM " +
          "my_mailer_metadatas MD " +
          "JOIN my_mailer_messages MM on (MM.my_mailer_metadata_id = MD.id) " + 
          "JOIN my_mailer_recipients MR on (MR.my_mailer_metadata_id = MD.id) " +
          
          "join " +
            "(select id, count(id) count, parent_message_id " +
            "from my_mailer_metadatas " +
            "group by parent_message_id) md_count on (md_count.parent_message_id = MD.parent_message_id) " +
            
          "LEFT JOIN people MD_person on (MD_person.id = MD.sender_id) " +
          "LEFT JOIN people MP on (MP.id = MR.recipient_id) " + 
          "LEFT JOIN organisations MO on (MO.id = MP.organisation_id) " + 
          
          "left join " + 
            "(select md3.id last_id, parent_message_id, message_summary, updated_at, sender_id " + 
            "from my_mailer_metadatas md3 " + 
            "where md3.id = " + 
            "(select max(id) " + 
            "from my_mailer_metadatas " + 
            "where parent_message_id = md3.parent_message_id)) " + 
            "md_max on (md_max.parent_message_id = MD.parent_message_id) " +
            
          "LEFT JOIN people MP_md_max on (MP_md_max.id = md_max.sender_id) " +
          
        "WHERE " +
          "MD.id = " + 
          "(select max(id) " + 
          "from my_mailer_metadatas " + 
          "where parent_message_id = MD.parent_message_id and sender_id = " + attributes_h[:sender_id].to_s + ") " + 
          
        "ORDER BY " + 
          "MD.created_at DESC " + 
          
        "LIMIT " + attributes_h[:starting_record].to_s + ", " + attributes_h[:results_per_page].to_s
        
      @messages = MyMailerMetadata.find_by_sql(@sql_s)
      
      raise 'Error while retrieving inbox message!' if !@messages || !@messages[0]
      
    rescue Exception => exc
      print "*** EXCEPTION [get_sent_messages]: " + exc.message
      @messages = nil
    end
    
    {:collection => @messages, :pagination_info => attributes_h}
    
  end
  
  def self.get_inbox_message(attributes_h)
    
    begin
      
      # Pagination logic - total no. of records
      @sql_s = "select count(md.parent_message_id) count " + 
        "from my_mailer_metadatas md " + 
        "where parent_message_id = " +
        "(select parent_message_id " + 
        "from my_mailer_metadatas " + 
        "where id = " + attributes_h[:message_id].to_s + ")"
  
      @results_count = MyMailerMetadata.find_by_sql(@sql_s)
      raise 'Error while retrieving inbox messages!' if !@results_count || !@results_count[0]
      attributes_h[:results_count] = @results_count[0].count
      
      # Change message status to 'Read'
      @recipient_message = MyMailerRecipient.find_by_my_mailer_metadata_id_and_recipient_id(
        attributes_h[:message_id].to_s, attributes_h[:recipient_id])
      @recipient_message.update_attribute(:message_status_id, 2) if @recipient_message
        
      @sql_s = "SELECT " +
          "MD.id, " +
          "MD.sender_id, " +
          "MD.subject, " +
          
          "MD.parent_message_id, " +
          "MD.message_status_id, " +
          "MD.message_type_id, " +
          "MD.sender_id, " +
          
          "MD_person.first_name sender_first_name, " +
          "MD_person.last_name sender_last_name, " +
          
          "md_count.count correspondence_count, " +
          
          "MD.created_at, " +
          "MM.message_html, " +
          "MR.message_status_id, " + 
          
          "MR.recipient_id, " + 
          "MP.first_name recipient_first_name, " +
          "MP.last_name recipient_last_name, " +
          "MO.id organisation_id, " +
          "MO.name organisation_name " +
          
        "FROM " +
        
          "my_mailer_metadatas MD " +
          "JOIN my_mailer_recipients MR on (MR.my_mailer_metadata_id = MD.id) " +
          "LEFT JOIN people MD_person on (MD_person.id = MD.sender_id) " +
          "LEFT JOIN my_mailer_messages MM on (MM.my_mailer_metadata_id = MD.id) " + 
          "LEFT JOIN people MP on (MP.id = MR.recipient_id) " + 
          "LEFT JOIN organisations MO on (MO.id = MP.organisation_id) " + 
          
        "left join " +
            "(select md2.parent_message_id, count(md2.parent_message_id) count " +
            "from my_mailer_metadatas md2 " +
            "group by parent_message_id " +
            "having md2.parent_message_id is not null) md_count on (md_count.parent_message_id = MD.id or " + 
              "md_count.parent_message_id = MD.parent_message_id) " +           
          
        "WHERE " +
        
          "MD.parent_message_id = (select parent_message_id from my_mailer_metadatas where id = " + attributes_h[:message_id].to_s + ") " + 
          
        "ORDER BY " + 
          "MD.created_at DESC " + 
          
        "LIMIT " + attributes_h[:starting_record].to_s + ", " + attributes_h[:results_per_page].to_s
          
      @messages = MyMailerMetadata.find_by_sql(@sql_s)
      
      raise "Message can't be found or you are not the reciever of this message!" if !@messages || !@messages[0]
      
    rescue Exception => exc
      print "*** EXCEPTION [get_inbox_message]: " + exc.message
      @messages = nil
    end
    
    {:collection => @messages, :pagination_info => attributes_h}
    
  end
  
  def self.get_sent_message(attributes_h)
    
    begin
      
      # Pagination logic - total no. of records
      @sql_s = "select count(md.parent_message_id) count " + 
        "from my_mailer_metadatas md " + 
        "where parent_message_id = " +
        "(select parent_message_id " + 
        "from my_mailer_metadatas " + 
        "where id = " + attributes_h[:message_id].to_s + ")"
  
      @results_count = MyMailerMetadata.find_by_sql(@sql_s)
      raise 'Error while retrieving inbox messages!' if !@results_count || !@results_count[0]
      attributes_h[:results_count] = @results_count[0].count
        
      @sql_s = "SELECT " +
          "MD.id, " +
          "MD.sender_id, " +
          "MD.subject, " +
          
          "MD.parent_message_id, " +
          "MD.message_status_id, " +
          "MD.message_type_id, " +
          "MD.sender_id, " +
          
          "MD_person.first_name sender_first_name, " +
          "MD_person.last_name sender_last_name, " +
          
          "md_count.count correspondence_count, " +
          
          "MD.created_at, " +
          "MM.message_html, " +
          "MR.message_status_id, " + 
          
          "MR.recipient_id, " + 
          "MP.first_name recipient_first_name, " +
          "MP.last_name recipient_last_name, " +
          "MO.id organisation_id, " +
          "MO.name organisation_name " +
          
        "FROM " +
        
          "my_mailer_metadatas MD " +
          "JOIN my_mailer_recipients MR on (MR.my_mailer_metadata_id = MD.id) " +
          "LEFT JOIN people MD_person on (MD_person.id = MD.sender_id) " +
          "LEFT JOIN my_mailer_messages MM on (MM.my_mailer_metadata_id = MD.id) " + 
          "LEFT JOIN people MP on (MP.id = MR.recipient_id) " + 
          "LEFT JOIN organisations MO on (MO.id = MP.organisation_id) " + 
          
        "left join " +
            "(select md2.parent_message_id, count(md2.parent_message_id) count " +
            "from my_mailer_metadatas md2 " +
            "group by parent_message_id " +
            "having md2.parent_message_id is not null) md_count on (md_count.parent_message_id = MD.id or " + 
              "md_count.parent_message_id = MD.parent_message_id) " +           
          
        "WHERE " +
        
          "MD.parent_message_id = (select parent_message_id from my_mailer_metadatas where id = " + attributes_h[:message_id].to_s + ") " + 
          
        "ORDER BY " + 
          "MD.created_at DESC " + 
          
        "LIMIT " + attributes_h[:starting_record].to_s + ", " + attributes_h[:results_per_page].to_s
          
      @messages = MyMailerMetadata.find_by_sql(@sql_s)
      
      raise "Message can't be found or you are not the reciever of this message!" if !@messages || !@messages[0]
      
    rescue Exception => exc
      print "*** EXCEPTION [get_sent_message]: " + exc.message
      @messages = nil      
    end
    
    {:collection => @messages, :pagination_info => attributes_h}
    
  end
  
  def self.get_reply_message(recipient_id, message_id)
    
    begin
      @sql_s = "SELECT " +
          "MD.id, " +
          "MD.sender_id, " +
          "MD.subject, " +
          "MD.created_at, " +
          "MM.message_html, " +
          "MR.message_status_id, " +
          "MD.parent_message_id, " +
          "MD.message_type_id, " +
          "MD.sender_id, " +
          
          "MD_person.first_name sender_first_name, " +
          "MD_person.last_name sender_last_name, " +
          
          "MR.recipient_id, " + 
          "MP.first_name recipient_first_name, " +
          "MP.last_name recipient_last_name, " +
          "MO.id organisation_id, " +
          "MO.name organisation_name " +
          
        "FROM " +
        
          "my_mailer_metadatas MD " +
          "JOIN my_mailer_messages MM on (MM.my_mailer_metadata_id = MD.id) " +
          "JOIN my_mailer_recipients MR on (MR.my_mailer_metadata_id = MD.id) " +
          "LEFT JOIN people MD_person on (MD_person.id = MD.sender_id) " +
          "LEFT JOIN people MP on (MP.id = MR.recipient_id) " + 
          "LEFT JOIN organisations MO on (MO.id = MP.organisation_id) " + 
          
        "WHERE " +
        
          "MR.recipient_id = " + recipient_id.to_s + " and " +
          "MD.id = " + message_id.to_s
          
      @message = MyMailerMetadata.find_by_sql(@sql_s)
      
      raise "Message can't be found or you are not the reciever of this message!" if !@message || !@message[0]
        
      @message = @message[0]
      
    rescue Exception => exc
      print "*** EXCEPTION: " + exc.message
      @message = nil    
    end
    
    @message
    
  end
  
end
