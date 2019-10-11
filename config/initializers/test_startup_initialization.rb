## Be sure to restart your server when you modify this file.
#
## -----------------------
## WINDOWS start-up setup
## -----------------------
#
#require 'win32ole'
#
#puts "TESTING new configuration for rails"
#
#wmi = WIN32OLE.connect("winmgmts://")
#processes = wmi.ExecQuery("select * from win32_process where CommandLine like '%flyc_mailer.rb'")
#is_found = false
#
#for process in processes do
#  if process.CommandLine && process.CommandLine.end_with?('flyc_mailer.rb')
#    puts "FOUND IT"
#    is_found = true
#    break
#  end
#  
##    puts "Name: #{process.Name}"
##    puts "CommandLine: #{process.CommandLine}"
##    puts "CreationDate: #{process.CreationDate}"
##    puts "WorkingSetSize: #{process.WorkingSetSize}"
##    puts
#end
#
#if !is_found
#  Thread.new do 
#    exec 'start "spec_server" /min ruby.exe c:\Applications\Ruby\projects\flyc\lib\daemons\flyc_mailer.rb'
#  end
#end
#
## ----------------------------------------
## LINUS (Hostingrails.com) start-up setup
## ----------------------------------------