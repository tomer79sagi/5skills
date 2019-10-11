#
# CONSTANTS DEFINTIONS
#
# People:
#  1 - New
#  2 - Registered
#  3 - Confirmed : email confirmed
#
# Person_Type:
#  1 - Candidate
#  2 - Agent
#  3 - Company Contact
#
# Organisation_Type:
#  1 - Agency
#  2 - Company
#
# Role_Application_Status:
#  1 - Created
#  2 - Sent
#  3 - Short Listed
#  4 - Interview Scheduled : could be a few interviews
#  5 - Waiting Decision : could be a few interviews
#  6 - Offer Made
#  7 - Accepted Offer
#  8 - Rejected Offer
#  9 - Application Declined
#
# Session[:mode]
#  1 - Create
#  2 - Update
#
class ApplicationNotesController < ApplicationController
  
  def prep_view_notes(application_id)
    # ******************************
    # SORTING
    # ******************************
    
    if params[:sort_by] && params[:sort_dir]
      @sort_by = params[:sort_by]
      
      @order_by = "note_updated_at" if params[:sort_by] == "update_date"
      
      if params[:sort_dir] == "up"
        @order_dir = "desc"
        @sort_dir = "down"
        @sort_dir_icon = " &darr;"
      elsif params[:sort_dir] == "down"
        @order_dir = "asc"
        @sort_dir = "up"
        @sort_dir_icon = " &uarr;"
      end
    else # Default
      @order_by = "note_updated_at"
      @order_dir = "desc"
      
      @sort_by = "update_date"
      @sort_dir = "down"
      @sort_dir_icon = " &darr;"
    end
    
    begin
      
      @sql = "select " +
          "APP_Notes.id note_id, " +
          "APP_Notes.note_contents description, " +
          "APP_Notes.updated_at note_updated_at " +
          
        "from " + 
          "notes APP_Notes " +
          
        "where " + 
          "APP_Notes.role_application_id = #{application_id} " +
          
        "order by " + 
          @order_by + " " + @order_dir
      
      @notes = Organisation.find_by_sql(@sql)
          
    rescue Exception => exc
      print "***** ERROR: " + exc
    end
  end
  
  #
  # UPDATE CANDIDATE
  #
  def update_application_note
    
    @note = Note.find_by_id(params[:note_id])
    
    flash[:notice] = flash[:error] = nil
    
    respond_to do |format|
      
      #TODO:Add data fields check and ask to confirm after clicking 'cancel'
      if params[:cancel]
        
        format.html { redirect_to :action => :view_application_notes, 
          :controller => :application_notes,
          :application_id => @note.role_application_id }
          
      else
    
        Note.transaction do
          
          begin
            
            @note.update_attributes!(params[:note])            
            
            flash[:notice] = 'Note was successfully updated.'
          
            # Reset the error queue
            flash[:error] = nil
            
            # Continue to edit the application, continue to 
            if params[:update]
              
              format.html { redirect_to :action => :view_application_note, 
                :controller => :application_notes,
                :note_id => @note.id }
                
            elsif params[:update_close]
              
              format.html { redirect_to :action => :view_application_notes, 
                :controller => :application_notes, 
                :application_id => @note.role_application_id }
                
            end
            
            format.js { render :inline => url_for(:controller => :application_notes, :action => params[:next]) }
            
          rescue Exception => exc
            
            flash[:error] = 'Errors were found in the fields below, please check the messages next to each field'
            
            populate_application_summary @note.role_application_id.to_s
            
            format.html { render 'edit_application_note.html', :layout => 'role_application'  }          
          end # rescue
        end # transaction
        
      end # else      
    end # respond_to
    
  end  
  
  #
  # UPDATE CANDIDATE
  #
  def save_application_note
    
    @is_new = true
    
    flash[:notice] = flash[:error] = nil
    
    respond_to do |format|
      
      #TODO:Add data fields check and ask to confirm after clicking 'cancel'
      if params[:cancel]
        
        format.html { redirect_to :action => :view_application_notes, 
          :controller => :application_notes,
          :application_id => params[:application_id] }
          
      else
        
        @note = Note.new(params[:note])
    
        Note.transaction do
          
          begin
            
            failed_validation = false
          
            @note.role_application_id = params[:application_id]
            
            failed_validation = true if !@note.valid?
            
            raise 'ERROR' if failed_validation
            
            @note.save(false)
            
            flash[:notice] = 'Note was successfully created.'
          
            # Reset the error queue
            flash[:error] = nil
            
            # Continue to edit the application, continue to 
            if params[:update]
              
              format.html { redirect_to :action => :view_application_note, 
                :controller => :application_notes,
                :note_id => @note.id }
                
            elsif params[:update_close]
              
              format.html { redirect_to :action => :view_application_notes, 
                :controller => :application_notes, 
                :application_id => @note.role_application_id }
                
            end
            
            format.js { render :inline => url_for(:controller => :application_notes, :action => params[:next]) }
            
          rescue Exception => exc
            
            flash[:error] = 'Errors were found in the fields below, please check the messages next to each field'
            
            populate_application_summary params[:application_id]
            
            format.html { render 'edit_application_note.html', :layout => 'role_application'  }          
          end # rescue
        end # transaction
        
      end # else      
    end # respond_to
    
  end
  
#
  # EDIT APPLICATION [NOTES]
  #
  def edit_application_note
    @note = Note.find_by_id(params[:note_id])
    
    populate_application_summary @note.role_application_id.to_s
    
    # Clear the notification buffers
    flash[:error] = nil
    flash[:notice] = nil
    
    render 'edit_application_note.html', :layout => 'role_application'
  end
  
    #
  # ADD CANDIDATE
  #
  def new_application_note
    populate_application_summary params[:application_id]
    
    @note = Note.new
    @note.note_contents = ""
    @note.role_application_id = params[:application_id]
    
    @is_new = true
    
    render 'edit_application_note.html', :layout => 'role_application'
  end  
  
  #
  # CREATE CANDIDATE
  #
  def create_application_note_quick
    
    @quick_add_note = Note.new(params[:quick_add_note])
    
    respond_to do |format|
      Note.transaction do
        begin
          failed_validation = false
          
          @quick_add_note.role_application_id = params[:application_id]
          
          failed_validation = true if !@quick_add_note.valid?
          
          if (!@quick_add_note.errors.empty?)
            puts "*** Error - Count: " + @quick_add_note.errors.count.to_s
            puts "*** Error - attributes: " + @quick_add_note.attributes.to_s
            puts "*** Error - messages: " + @quick_add_note.errors.each_full { |msg| puts msg }
          end
          
          raise 'ERROR' if failed_validation
          
          @quick_add_note.save(false)
          
          flash[:notice] = 'Note was successfully created.'
        
          # Reset the error queue
          flash[:error] = nil
          
          # Continue to edit the application, continue to 
          if params[:add]
            
            format.html { redirect_to :action => :view_application_notes, 
              :controller => :application_notes }
              
          elsif params[:add_edit]
            
            format.html { redirect_to :action => :edit_application_note, 
              :controller => :application_notes, 
              :note_id => @quick_add_note.id }
              
          end
            
          format.js { render :inline => url_for(:controller => :application_notes, :action => params[:next]) }
          
        rescue Exception => exc
          
          flash[:error] = 'Errors were found in the fields below, please check the messages next to each field'
          
          populate_application_summary params[:application_id]
          prep_view_notes params[:application_id]
          
          # Return the application_id to enable access to the othe application tabs
          @application_id = params[:application_id]
          
          format.html { render 'view_application_notes.html', :layout => 'role_application' }
          
        end     
      end
    end
  end  
  
#
  # EDIT APPLICATION [AGENCY]
  #
  def view_application_note
    
    @note = Note.find_by_id(params[:note_id])
    
    populate_application_summary @note.role_application_id.to_s
    
    render 'view_application_note.html', :layout => 'role_application'
  end  
  
  #
  # VIEW APPLICATION NOTES
  #
  def view_application_notes
    populate_application_summary params[:application_id] 
    prep_view_notes params[:application_id]
    
    # Return the application_id to enable access to the othe application tabs
    @application_id = params[:application_id]
    
    render 'application_notes/view_application_notes.html', :layout => 'role_application'
  end
  
  #
  # CREATE APPLICATION NOTE
  #
  def create_application_note
    @role_application_id = params[:application_id]
    
    @note = Note.new(params[:note])

    respond_to do |format|
      @note.transaction do
        begin
          if params[:note] && params[:note][:note_contents] && !params[:note][:note_contents].empty?
            @note.role_application_id = @role_application_id
            @note.save!
            
            flash[:notice] = 'Application Note was successfully created.'
          end
          
          # Reset the error queue
          flash[:error] = nil          
          
          # Finally if all went well, set the editing mode to 'update'
          session[:mode] = 2
          
          # Continue to edit the application, continue to 
          format.html { redirect_to :action => :view_applications, 
            :controller => :role_applications, 
            :application_id => @role_application_id }
            
          format.js { render :inline => url_for(:controller => :role_applications, :action => params[:next]) }            
        rescue Exception => exc
          flash[:error] = exc.message
          format.html { render params[:page] + '.html', :layout => 'role_application' }
          format.js { render :inline => url_for(:controller => :role_applications, :action => session[:mode_action]) }
        end     
      end
    end
  end  
  
  def delete_application_note
    respond_to do |format|
      
      @note = Note.find_by_id(params[:note_id])
      @application_id = @note.role_application_id
      
      Person.transaction do
        begin
          
          # 2. Destroy the Agent record
          @note.destroy
          
          flash[:notice] = "Note was deleted successfully!"
          
          populate_application_summary @application_id.to_s
            
          format.html { redirect_to :action => :view_application_notes, 
            :controller => :application_notes,
            :application_id => @application_id}
          
        rescue Exception => exc
          
          flash[:error] = 'Errors were found in the fields below, please check the messages next to each field'
          
          populate_application_summary @application_id.to_s
          
          format.html { render 'view_application_notes.html', :layout => 'role_application' }    
        end # rescue
      end # transaction
          
    end # respond_to
  end  

end