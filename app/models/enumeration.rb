class Enumeration < ActiveRecord::Base
  validates_columns :color, :severity
end