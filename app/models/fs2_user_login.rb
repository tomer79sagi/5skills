class Fs2UserLogin < ActiveForm
  attr_accessor :email, :password
  
  validates_presence_of :email, :password
end