require 'digest/sha2'

class HashAndSaltPersonPasswords < ActiveRecord::Migration
  def self.up
      Person.find(:all).each do |person|
        
        # This logic is copied to the Person model for registration of new people
        @salt = ActiveSupport::SecureRandom.base64(8)
        
        if !person.password
          @temp_password = "password"
        else
          @temp_password = person.password
        end
          
        person.salt = @salt
        person.hashed_password = Digest::SHA2.hexdigest(@salt + @temp_password)
        person.password = "{hashed}"
        person.save(false)
        
      end
    
  end

  def self.down
    Person.find(:all).each do |person|
          
        person.salt = nil
        person.hashed_password = nil
        person.save(false)
        
      end
  end
end
