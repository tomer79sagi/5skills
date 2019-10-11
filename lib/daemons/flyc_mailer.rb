#!/usr/bin/env ruby

# You might want to change this
ENV["RAILS_ENV"] ||= "development"

require File.dirname(__FILE__) + "/../../config/environment"
require 'net/pop'
require 'tmail'

$running = true
Signal.trap("TERM") do 
  $running = false
end

SLEEP_TIME = 5

while($running) do
  
  #########################################
  # 1. Check new personal 'flyc' emails
  #########################################
  
  @config = YAML.load(IO.read("#{RAILS_ROOT}/config/toemail_mail.yml"))
  
  pop = Net::POP3.new(@config[RAILS_ENV]['server'])
  pop.enable_ssl(OpenSSL::SSL::VERIFY_NONE) if @config[RAILS_ENV]['ssl']
  pop.start(@config[RAILS_ENV]['username'], @config[RAILS_ENV]['password'])
  unless pop.mails.empty?
     
    pop.each_mail do |m|
      emails = TMail::Mail.parse(m.pop)
  
      puts "From: " + emails.from.to_s
      puts "To: " + emails.to.to_s
      puts "Subjedt: " + emails.subject.to_s
      puts "Body: " + emails.body.to_s
    end
  end
  pop.finish
  
  puts "This daemon is still running at #{Time.now}.\n"
  
  ##############################################
  # 2. Check for 'pending' emails and send them
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