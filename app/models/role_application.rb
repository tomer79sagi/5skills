class RoleApplication < ActiveRecord::Base
  belongs_to :role, :class_name => 'Role', :foreign_key => "role_id"
  belongs_to :person, :class_name => 'Person', :foreign_key => "person_id"
  
  has_many :notes
  
  validates_format_of :status_id,
    :with => /^[1-9]+$/ix,
    :message => "cannot be empty!",  
    :allow_nil => true,
    :allow_blank => true
    
  def self.sort_mapping
      {"title" => "role_title",
      "status" => "application_status_id",
      "agency" => "agency_name",
      "company" => "company_name",
      "closing_date" => "role_close_date",
      "update_date" => "application_updated_at"}
  end
end
