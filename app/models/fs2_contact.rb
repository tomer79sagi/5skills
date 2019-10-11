class Fs2Contact < ActiveRecord::Base
  
  CONTACT_TYPES = {:agency => 1, :company => 2}
  
  belongs_to :organistion, :class_name => 'Fs2Organisation', :foreign_key => "organisation_id"
  
  validates_presence_of :full_name
  
end
