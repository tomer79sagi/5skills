#!/usr/bin/env ruby

# You might want to change this
ENV["RAILS_ENV"] ||= "development"

require File.dirname(__FILE__) + "/../../config/environment"
require 'net/pop'
require 'net/http'
require 'net/smtp'
require 'tlsmail'
require 'tmail'

$running = true
Signal.trap("TERM") do 
  $running = false
end

SLEEP_TIME = 5

while($running) do
  
  #########################################
  # 1. Check new personal '5skills.me' emails
  #########################################
  
  @config = YAML.load(IO.read("#{RAILS_ROOT}/config/toemail_mail.yml"))
   
  
  pop = Net::POP3.new(@config[RAILS_ENV]['server'])
  pop.enable_ssl(OpenSSL::SSL::VERIFY_NONE) if @config[RAILS_ENV]['ssl']
  pop.start(@config[RAILS_ENV]['username'], @config[RAILS_ENV]['password'])
  unless pop.mails.empty?
     
    pop.each_mail do |m|
      emails = TMail::Mail.parse(m.pop)
      
      em_params = {}
      em_params[:from] = em_params[:reply_to] = emails.from.to_s
      em_params[:to] = emails.to
      em_params[:subject] = emails.subject
      em_params[:content] = emails.body.to_s
        
      puts "From: " + emails.from.to_s
      puts "To: " + emails.to.to_s
      puts "Subject: " + emails.subject.to_s
      puts "Body: " + emails.body.to_s
      
      # If 'To' is Tomer's phone '0528684411' then forward the email
      # We need to ensure the forwarded email appears correctly
      phone = emails.to.to_s.split('@')[0]
      a = phone.scan(/^\d+$/).any?
      next if !a
      
      # -- 1.1 Check if the user is registered in the system
      e_user = EmailUser.find_or_create_by_phone(phone) # Find existing users with a registered state
            
      if e_user.status == 1 # --- User is registered
        
        puts "User exists"
      
      elsif !e_user.status || e_user.status == 0 # User exists but not registered or doesn't exist at all
        
        # -- 2.1 Send SMS
        # * Rest Call example: https://rest.nexmo.com/sms/json?api_key=b955b949&api_secret=3e1a5289&from=NEXMO&to=972528684411&text=Welcome+to+Nexmo

        url = URI.parse("https://rest.nexmo.com/sms/json")
        req = Net::HTTP::Post.new(url.request_uri)
        req.set_form_data({
          'api_key' => 'b955b949', 
          'api_secret' => '3e1a5289',
          'from' => '012.email',
          'to' => '972' + phone[1..9],
          'text' => 'Email from: ' + emails.from.to_s + '. Subject: ' + emails.subject.to_s + '.'
        })
        http = Net::HTTP.new(url.host, url.port)
        http.use_ssl = (url.scheme == "https")
        response = http.request(req)
                
      end
       
      if phone == '0528684411'
          
        
        ##############################################
        # 2.1 Forward the email (assuming the user had registered)
        ##############################################
        BaseMailer.deliver_forward_email(em_params)


      end
      
    end
  end
  pop.finish
  
  puts "This daemon is still running at #{Time.now}.\n"
     
  
  ##############################################
  # 3. Check for 'pending' emails and send them
  ##############################################
  
  @sql_s = "SELECT * FROM my_mailer_emails order by priority asc"
  
  @emails = MyMailerEmail.find_by_sql(@sql_s)
  
  if @emails
        
    @emails.each do |email|
      
      # Create 'MyMailer' object
      # @mailer_email = MyMailer.deliver_init(email.headers, email.body_attributes, email.template)

    end
  
  end
  
  sleep(SLEEP_TIME)
  
end