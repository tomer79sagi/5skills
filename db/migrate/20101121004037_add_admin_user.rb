class AddAdminUser < ActiveRecord::Migration
  def self.up
    begin
      
      # Create the admin user
      # Use 'status_id' of 2 to overcome the current 'website' validation rules
      person = Person.new(
        "first_name" => "Flyc",
        "last_name" => "Admin",
        "primary_email" => "admin@flyc.co.nz",
        "password" => "*0flyc0*",
        "password_confirmation" => "*0flyc0*",
        "status_id" => 2,
        "person_type_id" => 0
        )
      
      person.save!
      
      # Update the 'admin' user and set the 'status_id' to 4, i.e. must change password next time
      # This status assumes the user already passed stasuses 1 through to 3
      person.update_attribute("status_id", 4)
      
    rescue Exception => exc
      print exc.message
    end
  end

  def self.down
    person = Person.find_by_primary_email("admin@flyc.co.nz")
    
    person.delete
  end
end