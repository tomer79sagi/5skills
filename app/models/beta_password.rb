class BetaPassword < ActiveForm
  attr_accessor :beta_password
  
  validates_presence_of :beta_password
  
  validates_format_of :beta_password, 
    :with => /(ybboj)/ix,
    :message=>"is wrong!" 
end