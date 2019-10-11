class PeopleController < ApplicationController
  
  #
  # VIEW CANDIDATES
  #
  def view_candidates
    @people = Person.all
    
    render 'index.html'
  end

  #
  # SHOW CANDIDATE
  #
  def show_candidate
    @person = Person.find(params[:candidate_id])
    @contact_detail = @person.contact_detail
    
    render 'show.html'
  end

  #
  # ADD CANDIDATE
  #
  def add_candidate
    if @person.nil?
      @person = Person.new
      @contact_detail = ContactDetail.new
    end
    
    render 'new.html'
  end

  #
  # EDIT CANDIDATE
  #
  def edit_candidate
    @person = Person.find(params[:candidate_id])
    @contact_detail = @person.contact_detail
    
    render 'edit.html'
  end
  
  #
  # CREATE CANDIDATE
  #
  def create_candidate
    @person = Person.new(params[:person])
    @contact_detail = ContactDetail.new(params[:contact_detail])
    @person.contact_detail = @contact_detail
    
    # Temporary, adding the email address to the primary_email in the Person instance
    @person.primary_email = @contact_detail.email

    respond_to do |format|
      if @person.save
        flash[:notice] = 'Person was successfully created.'
        format.html { redirect_to :show_candidate, :candidate_id => @person.id }
        #format.xml  { render :xml => @person, :status => :created, :location => @person }
      else
        format.html { redirect_to :add_candidate }
        #format.xml  { render :xml => @person.errors, :status => :unprocessable_entity }
      end
    end
  end

  #
  # UPDATE CANDIDATE
  #
  def update_candidate
    @person = Person.find(params[:candidate_id])
    @contact_detail = ContactDetail.new(params[:contact_detail])
    @person.contact_detail = @contact_detail    

    respond_to do |format|
      if @person.update_attributes(params[:person])
        flash[:notice] = 'Person was successfully updated.'
        format.html { redirect_to :show_candidate, :candidate_id => @person.id }
        #format.xml  { head :ok }
      else
        format.html { render :action => "edit_candidate" }
        #format.xml  { render :xml => @person.errors, :status => :unprocessable_entity }
      end
    end
  end

  #
  # REMOVE CANDIDATE
  #
  def remove_candidate
    @person = Person.find(params[:candidate_id])
    @person.destroy

    respond_to do |format|
      format.html { redirect_to :view_candidates }
      format.xml  { head :ok }
    end
  end
end
