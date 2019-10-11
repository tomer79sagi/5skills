#require 'capistrano/ext/multistage'

set :default_stage, "production"
set :stages, %w(testing production)

set :application, "jobby_prod"
set :domain, "5skills.me"
set :user, "jobbyco"

set :repository,  "file:///home/jobbyco/svn/flyc/trunk"
# set :repository,  "svn://flyc.co.nz/home/jobbyco/svn/flyc/trunk"
# set :repository,  "svn+ssh://jobbyco@localhost/home/jobbyco/svn/flyc/trunk"
# set :repository,  "svn+ssh://jobbyco@flyc.co.nz/home/jobbyco/svn/flyc/trunk"

set :use_sudo, false                                  # HostingRails users don't have sudo access
set :deploy_to, "/home/#{user}/applications/#{application}"   # Where on the server your app will be deployed
set :deploy_via, :checkout                            # For this tutorial, svn checkout will be the deployment method, but check out :remote_cache in the future
set :group_writable, false                            # By default, Capistrano makes the release group-writable. You don't want this with HostingRails

#default_run_options[:pty] = true
# Cap won't work on windows without the above line, see
# http://groups.google.com/group/capistrano/browse_thread/thread/13b029f75b61c09d
# Its OK to leave it true for Linux/Mac

# ssh_options[:keys] = %w(~/.ssh/id_dsa) 

role :app, domain
role :web, domain
role :db,  domain, :primary => true



after "deploy:setup", "db:test:setup"