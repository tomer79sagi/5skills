load 'deploy' if respond_to?(:namespace) # cap2 differentiator
load 'config/deploy'



# ------------------ #
#     DATABASE
# ------------------ #

namespace :db do
  
  task :setup do
    transaction do
      run "mkdir -p #{shared_path}/db"
    end
  end
  
  task :rollback, :roles => :db do
    transaction do
  
      # Rollback one version back, using 'STEP=X' we can define exact no. of steps to rollback to
      run "cd #{current_path}; rake db:rollback"
      
    end
  end
    
  task :migrate, :roles => :db do
    transaction do
      
      run "cd #{current_path}; rake db:migrate"
      
    end
  end
  
  namespace :prod_env do
    task :backup, :roles => :db do
      transaction do
        stamp = Time.now.utc.strftime("%Y%m%d%H%M%S")
        db_folder = "#{shared_path}/db"
        prod_db_dump = "#{db_folder}/backup_prod_#{stamp}.sql"
        
        find_and_execute_task("db:setup")
  
        run "mysqldump --user=jobbyco_jobby --password=*0jobby0* jobbyco_main > #{prod_db_dump}"
      end
    end
  end
  
  namespace :test_env do
    
    task :dump_prod, :roles => :db do
      transaction do
        stamp = Time.now.utc.strftime("%Y%m%d%H%M%S")
        db_folder = "#{shared_path}/db"
        prod_db_dump = "#{db_folder}/backup_prod_#{stamp}.sql"
        
        find_and_execute_task("db:setup")
  
        run "mysqldump --user=jobbyco_jobby --password=*0jobby0* jobbyco_main > #{prod_db_dump}"
        
        # Clean the DB, remove existing test database and create a new empty DB
        run 'mysql --user=jobbyco_test --pass=tomer66 --execute="drop database jobbyco_test"'
        run 'mysql --user=jobbyco_test --pass=tomer66 --execute="create database jobbyco_test"'
        
        # Then import the production database into the new DB
        run "mysql --user=jobbyco_test --pass=tomer66 jobbyco_test < #{prod_db_dump}"
        
        run "rm #{prod_db_dump}"
      end
    end
    
    task :backup, :roles => :db do
      transaction do
        stamp = Time.now.utc.strftime("%Y%m%d%H%M%S")
        db_folder = "#{shared_path}/db"
        
        find_and_execute_task("db:setup")
  
        run "mysqldump --user=jobbyco_test --password=tomer66 jobbyco_test > #{db_folder}/backup_test_#{stamp}.sql"
      end
    end
    
    # > cap deploy rails_env=beta
    # Will allow the user to use 'ENV['rails_env']' inside a task
    task :restore, :roles => :db do
      transaction do
        stamp = Time.now.utc.strftime("%Y%m%d%H%M%S")
        db_folder = "#{shared_path}/db"
        
        find_and_execute_task("db:setup")
  
        run "mysql --user=hruser_dbuser --pass=*** hruser_dbname < db/your_schema.sql"
      end
    end
    
  end
end



# ------------------ #
#    APPLICATION
# ------------------ #

namespace :app do
  
  task :mytest do
     if releases.length < 2 
       abort "could not rollback the code because there is no prior release" 
     else 
       rake = fetch(:rake, "rake") 
       rails_env = fetch(:rails_env, "production") 
       migrate_env = fetch(:migrate_env, "") 
       migrate_target = fetch(:migrate_target, :latest) 
       
       # The following line extracts the last migration version from the appropriate folder
       #run "cd #{current_path}; #{rake} RAILS_ENV=#{rails_env} #{migrate_env} db:migrate VERSION=`cd #{File.join(previous_release, 'db', 'migrate')} && ls -1 [0-9]*_*.rb | tail -1 | sed -e s/_.*$//`"
       run "echo #{current_path}; #{rake} RAILS_ENV=#{rails_env} #{migrate_env} db:migrate VERSION=`cd #{File.join(previous_release, 'db', 'migrate')} && ls -1 [0-9]*_*.rb | tail -1 | sed -e s/_.*$//`"
     end 
  end
  
  
  
  # ------------------ #
  #       TEST
  # ------------------ #
  
  namespace :test_env do

    task :deploy, :roles => :app do
     
      transaction do
        
        # Display maintenance page to visitors
        find_and_execute_task("deploy:web:disable")
      
        find_and_execute_task("deploy:update_code")
        
        run "cd #{release_path}/config; mv environment.rb environment.rb.offline"
        run "cd #{release_path}/config; mv environment.rb.online.test environment.rb"
        
        run "cd #{release_path}/config; mv database.yml database.yml.offline"
        run "cd #{release_path}/config; mv database.yml.online.test database.yml"
        
        run "cd #{release_path}/public; mv .htaccess.online.test .htaccess"
        run "cd #{release_path}/public; mv dispatch.rb.online.test dispatch.rb"
        run "cd #{release_path}/public; mv dispatch.fcgi.online.test dispatch.fcgi"
        run "cd #{release_path}/public; mv dispatch.cgi.online.test dispatch.cgi"
        
        find_and_execute_task("deploy:symlink")
        
        # DB Backup
        find_and_execute_task("db:test_env:backup")
        
        # DB Replace test DB with production DB
        find_and_execute_task("db:test_env:dump_prod")
        
        # DB Migrations
        find_and_execute_task("db:migrate")
        
        # Restart the application
        find_and_execute_task("app:test_env:restart")
        
        # Clean no. of releases
        find_and_execute_task("deploy:cleanup")
        
        # Remove maintenance page to visitors
        find_and_execute_task("deploy:web:enable")
      
      end
      
    end
    
    task :rollback, :roles => :app do
     
      transaction do
        
        # Display maintenance page to visitors
        find_and_execute_task("deploy:web:disable")
        
        find_and_execute_task("deploy:rollback:code")
        
        # DB Backup
        # !! Should tag the file with "ROLLBACK" so it's easy to identify for future data correction
        find_and_execute_task("db:test_env:backup")
        
        # DB Migrations
        find_and_execute_task("db:rollback")
        
        # Restart the application
        find_and_execute_task("app:test_env:restart")
        
        # Clean no. of releases
        find_and_execute_task("deploy:cleanup")
        
        # Remove maintenance page to visitors
        find_and_execute_task("deploy:web:enable")
      
      end
      
    end
  
    task :fbackup, :roles => :app do 
    
      transaction do
      
        on_rollback { run "echo Blag, Rolling back" }
      
        #$(date +%Y%m%d%H%M%S)_backup
      
        set :dd, "backup"
       
        # Create a backup directory of the live version
        run "mkdir ~/jobby_test/releases/#{dd}"
       
        # Copy the current version to the backup folder
        run "cp -R ~/jobby_test/. ~/jobby_test/releases/#{dd}"
        
      end
    end
    
    task :start, :roles => :app do
      run "touch #{deploy_to}/current/tmp/restart.txt"
    end
       
    task :restart, :roles => :app do
      run "touch #{deploy_to}/current/tmp/restart.txt"
    end

  end



  # ------------------ #
  #     PRODUCTION
  # ------------------ #
  
  namespace :prod_env do
  
  task :restart, :roles => :app do
      # Kill the 'dispatch.fcgi' process first
      # run "pkill -9 -u jobbyco dispatch.fcgi"
      
      # Next time someone tries to access the site, the dispatch.fcgi will be automatically launched
    end

    task :deploy, :roles => :app do
     
      transaction do
        
        # Display maintenance page to visitors
        find_and_execute_task("deploy:web:disable")
      
        find_and_execute_task("deploy:update_code")
        
        run "cd #{release_path}/config; mv environment.rb environment.rb.offline"
        run "cd #{release_path}/config; mv environment.rb.online.prod environment.rb"
        
        run "cd #{release_path}/config; mv database.yml database.yml.offline"
        run "cd #{release_path}/config; mv database.yml.online.prod database.yml"
        
        run "cd #{release_path}/public; mv .htaccess.online.prod .htaccess"
        run "cd #{release_path}/public; mv dispatch.rb.online.prod dispatch.rb"
        run "cd #{release_path}/public; mv dispatch.fcgi.online.prod dispatch.fcgi"
        run "cd #{release_path}/public; mv dispatch.cgi.online.prod dispatch.cgi"
        
        find_and_execute_task("deploy:symlink")
        
        # DB Backup
        find_and_execute_task("db:prod_env:backup")
        
        # Different from the test environment, all data will be retained
        # The database will just be migrated forward for the new release
        
        # DB Migrations
        find_and_execute_task("db:migrate")
        
        # Change permissions
        run "cd #{release_path}; find public -type d -exec chmod 0755 {} \\;"
        run "cd #{release_path}; find public -type f -exec chmod 0644 {} \\;"
        run "cd #{release_path}; chmod 0755 public/dispatch.*"
        run "cd #{release_path}; chmod -R 0755 script"
        
        # Restart the application
        find_and_execute_task("app:prod_env:restart")
        
        # Clean no. of releases
        find_and_execute_task("deploy:cleanup")
        
        # Remove maintenance page to visitors
        find_and_execute_task("deploy:web:enable")
      
      end
      
    task :deploy_quick, :roles => :app do
     
      transaction do
        
        # Display maintenance page to visitors
        find_and_execute_task("deploy:web:disable")
      
        find_and_execute_task("deploy:update_code")
        
        run "cd #{release_path}/config; mv environment.rb environment.rb.offline"
        run "cd #{release_path}/config; mv environment.rb.online.prod environment.rb"
        
        run "cd #{release_path}/config; mv database.yml database.yml.offline"
        run "cd #{release_path}/config; mv database.yml.online.prod database.yml"
        
        run "cd #{release_path}/public; mv .htaccess.online.prod .htaccess"
        run "cd #{release_path}/public; mv dispatch.rb.online.prod dispatch.rb"
        run "cd #{release_path}/public; mv dispatch.fcgi.online.prod dispatch.fcgi"
        run "cd #{release_path}/public; mv dispatch.cgi.online.prod dispatch.cgi"
        
        find_and_execute_task("deploy:symlink")
        
        # Change permissions
        run "cd #{release_path}; find public -type d -exec chmod 0755 {} \\;"
        run "cd #{release_path}; find public -type f -exec chmod 0644 {} \\;"
        run "cd #{release_path}; chmod 0755 public/dispatch.*"
        run "cd #{release_path}; chmod -R 0755 script"
        
        # Clean no. of releases
        find_and_execute_task("deploy:cleanup")
        
        # Remove maintenance page to visitors
        find_and_execute_task("deploy:web:enable")
      
      end
      
    end
    
    task :rollback, :roles => :app do
     
      transaction do
        
        # Display maintenance page to visitors
        find_and_execute_task("deploy:web:disable")
        
        find_and_execute_task("deploy:rollback:code")
        
        # DB Backup
        # !! Should tag the file with "ROLLBACK" so it's easy to identify for future data correction
        find_and_execute_task("db:prod_env:backup")
        
        # DB Migrations
        find_and_execute_task("db:rollback")
        
        # Restart the application
        find_and_execute_task("app:prod_env:restart")
        
        # Clean no. of releases
        find_and_execute_task("deploy:cleanup")
        
        # Remove maintenance page to visitors
        find_and_execute_task("deploy:web:enable")
      
      end
      
    end
    
    task :start, :roles => :app do
      run "rm -rf /home/#{user}/public_html;ln -s #{current_path}/public /home/#{user}/public_html"
    end
  
    
    
  end
end
  end