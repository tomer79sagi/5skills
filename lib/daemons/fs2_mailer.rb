#!/usr/bin/env ruby

# You might want to change this
# ENV["RAILS_ENV"] ||= "production"

require File.dirname(__FILE__) + "/../../config/environment"
require 'net/pop'
require 'tmail'

$running = true
Signal.trap("TERM") do 
  $running = false
end

SLEEP_TIME = 10

while($running) do
  
  puts "This daemon is still running at #{Time.now}.\n"
  
  ##############################################
  # 2. Check for 'pending' emails and send them
  ##############################################
  
  @sql_s = "SELECT * FROM fs2_mailer_emails order by priority asc"
  
  @emails = Fs2MailerEmail.find_by_sql(@sql_s)
  
  if @emails
        
    @emails.each do |email|
      
      if email.body_attributes.nil?
      
        # 2. Output email attributes
        email.body_attributes.each do |k, v| # 1st level attributes
          
          puts "C: " + k.to_s
        
          if k == "js_results_array" # js_results
            
            v.each do |elm1|
              elm1[1].each do |obj_k, obj_v|
                puts "A: " + elm1[0].to_s + " ; " + obj_k.to_s + "|" + obj_v.to_s
              end
            end
            
          elsif k == "js_match" # Single job_seeker match
           
            v.each do |obj_k, obj_v|
              if obj_k == "files" && obj_v[:cv]
                puts "--- File: " + obj_v[:cv][:id].to_s
              end
            
              puts "A: " + obj_k.to_s + "|" + obj_v.to_s
            end
            
          else
            
            puts "B: " + v.to_s
            
          end
        end
        
      end # if email.body_attributes.nil?
              
      # 3. Create 'MyMailer' object
      @mailer_email = Fs2Mailer.deliver_init(email.headers, email.body_attributes, email.template)
      
      # 4. Delete 'email' object
      Fs2MailerEmail.destroy(email.id)
      
    end
  
  end
  
  sleep(SLEEP_TIME)
  
end