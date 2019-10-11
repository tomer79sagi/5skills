class Note < ActiveRecord::Base
  belongs_to :role_application
  
  validates_presence_of :note_contents
end
