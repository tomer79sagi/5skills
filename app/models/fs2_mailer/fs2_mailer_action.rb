#
# MyMailerAction inherits from 'Activity'. They share the same core 'Activity' parameters.
# This class is specific for email redirects so will have email specfiic enhancements but hte core functionality:
# I.e, actions, controller, parameter, values etc will be the same
#
# Relationship to 'MyMailerMetadata' is to ensure that if a message is deleted
#
class Fs2MailerAction < ActiveRecord::Base
  
#  belongs_to :mailer_metadata, :class_name => 'MyMailerMetadata', :foreign_key => "my_mailer_metadata_id"
  
  def self.create_o(params_h, friendly_names_h)
    @action = Fs2MailerAction.new
#    @action.person_id = 0 # in case there is no current logged in user
    @action.action = params_h[:action]
    @action.controller = params_h[:controller]
    
    @parameters_h = params_h.select {|k, v| k.to_s.include? "_id"}
    
    if !@parameters_h.empty?
      
      @friendly_names_a = Array.new
      
      # Create array of 2 elements where each element is the array of either the IDs or the Names
      @parameters_h = @parameters_h.transpose
      
      # Retrieve the 1st element (i.e. array of all IDs)
      @ids = @parameters_h[0]
      @action.parameter_ids = @ids.join(",")
      
      # Retrieve the 2nd element (i.e. array of all Names)
      @action.parameter_names = @parameters_h[1].join(",")
      
      # Populate an Array for the friendly_names with the same index values as the @ids array
      # This will help assigning and retrieving the right information for the right elements
      if friendly_names_h
        friendly_names_h.each {|k, v|
          @id_index = @ids.index(k)
          
          @friendly_names_a[@id_index] = v if @id_index
        }
              
        @action.parameter_values = @friendly_names_a.join(",")
      end
    end
    
    @action
  end
  
end
