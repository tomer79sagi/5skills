#
# MyMailerAction inherits from 'Activity'. They share the same core 'Activity' parameters.
# This class is specific for email redirects so will have email specfiic enhancements but hte core functionality:
# I.e, actions, controller, parameter, values etc will be the same
#
# Relationship to 'MyMailerMetadata' is to ensure that if a message is deleted
#
class MyMailerAction < ActiveRecord::Base
  
  belongs_to :mailer_metadata, :class_name => 'MyMailerMetadata', :foreign_key => "my_mailer_metadata_id"
  
  def self.create_o(params_h, friendly_names_h)
    @activity = Activity::create_o(params_h, friendly_names_h)
    
    @action = MyMailerAction.new
    @action.action = @activity.action
    @action.controller = @activity.controller
    @action.parameter_ids = @activity.parameter_ids
    @action.parameter_names = @activity.parameter_names
    @action.parameter_values = @activity.parameter_values
    
    @action
  end
  
end
