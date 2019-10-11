#!/usr/bin/env ruby

# You might want to change this
# ENV["RAILS_ENV"] ||= "production"

require File.dirname(__FILE__) + "/../../config/environment"
# require 'net/pop'
# require 'tmail'
require 'oauth'
require 'json'
require 'net/http'

$running = true
Signal.trap("TERM") do 
  $running = false
end

SLEEP_TIME = 10

while($running) do
  
  puts "The 'user_network_crawler' daemon is still running at #{Time.now}.\n"
  
  ##############################################
  # 2. Check for 'pending' emails and send them
  ##############################################
  
  # @sql_s = "SELECT * FROM fs2_mailer_emails order by priority asc"
  
  LINKEDIN_API_KEY = 'qyskfuh30ovp'
  LINKEDIN_API_SECRET = 'FyB8irPnXoxZNEvl'
  
  users = Fs2User.find(
    :all,
    :joins => ["LEFT JOIN fs2_user_connectors on fs2_user_connectors.user_id = fs2_users.id", 
      "LEFT JOIN `fs2_user_network_connections` ON fs2_user_network_connections.user_connector_id = fs2_user_connectors.id"],
    :select => "fs2_user_connectors.*, fs2_user_network_connections.friend_linkedin_id", 
    :conditions => ["fs2_user_connectors.user_id = ?", 137.to_s])
  
  i = 1
  users.each do |single_user|
    puts "--- " + single_user.linkedin_first_name + " " + single_user.linkedin_first_name + " : " + single_user.friend_linkedin_id
    
    
    
    configuration = { :site => 'https://api.linkedin.com',
      :authorize_path => '/uas/oauth/authenticate',
      :request_token_path => '/uas/oauth/requestToken?scope=r_fullprofile+r_emailaddress+r_network+r_contactinfo',
      :access_token_path => '/uas/oauth/accessToken' }
     
    consumer = OAuth::Consumer.new(LINKEDIN_API_KEY, LINKEDIN_API_SECRET, configuration)
    
    
    
    if single_user.friend_linkedin_id != "private"
      access_token = OAuth::AccessToken.new(consumer, single_user.linkedin_access_token, single_user.linkedin_access_secret)      
      response = access_token.get("http://api.linkedin.com/v1/people/id=#{single_user.friend_linkedin_id}(id,first-name,last-name,email-address,headline,location:(name,country:(code)),industry,skills,positions,educations,connections:(id,first-name,last-name,email-address,industry,skills,positions)?format=json")  
        
      if response == Net::HTTPUnauthorized || response.message == 'Unauthorized'
        puts "unauthorized..."
        next
      end 
      
      connection_obj = JSON.parse(response.body)
      my_profile['skills']['values'].each do |skill_obj|
        puts " --- Skill: " + skill_obj['skill']['name'].to_s
      end
    end
    
    break if i == 10
    
    i += 1
  end
  
  # @emails = Fs2MailerEmail.find_by_sql(@sql_s)
  
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