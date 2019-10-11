class Fs2Organisation < ActiveRecord::Base
  
  ORGANISATION_TYPES = {:agency => 1, :company => 2}
  
  validates_presence_of :name
  
  validates_format_of :website, 
    :with => /^(http|https):\/\/[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,5}(([0-9]{1,5})?\/.*)?$/ix,
    :message=>"is not a valid website address!",
    :allow_blank => true
  
end
