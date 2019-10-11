#!/usr/bin/env ruby

# You might want to change this
ENV["RAILS_ENV"] ||= "production"

require File.dirname(__FILE__) + "/../../config/environment"
require 'mechanize'

agent = Mechanize.new
page = agent.get('http://google.com/')

pp page

#a = Mechanize.new { |agent|
#  agent.user_agent_alias = 'Mac Safari'
#}
#
#a.get('http://google.com/') do |page|
#  search_result = page.form_with(:name => 'f') do |search|
#    search.q = 'Hello world'
#  end.submit
#  
#  puts search_result.body
#
#  search_result.links.each do |link|
##    puts link.text
#  end
#end
