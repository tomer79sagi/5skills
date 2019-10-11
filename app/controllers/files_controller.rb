class FilesController < ApplicationController
    

  
  def view_files
    @user_files = FlycFile.find_all_by_person_id(session[:user].id)
    
#    @files = Dir.glob("public/uploads/*")
    
    respond_to do |format|
      format.html { render 'view_files.html', :layout => 'role_application' }
    end
  end
  
  #
  # CREATE CANDIDATE
  #
  def create_file_quick
    
    @user_files = FlycFile.find_all_by_person_id(session[:user].id)
    
    FlycFile.transaction do
      
      @file_form = FlycFile.new(params[:file_form])
      @file_form.person_id = session[:user].id
      raise 'ERRORS: ' + @file_form.errors.to_xml if !@file_form.valid?
      
      @file_form.save(false)
      
    end

    flash[:notice_hold] = 'Successfully uploaded the file.'
    redirect_to :action => :view_files, :controller => :files
  
  rescue => e
    puts 'Upload failed. ' + e.to_s
    flash[:error] = 'Upload failed. Please try again.'
    
    # Delete the file
    @file_form.delete
    
    respond_to do |format|
      format.html { render 'view_files.html', :layout => 'role_application' }
    end
  end
  
 end
