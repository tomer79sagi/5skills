class PopulatePersonToOrganisations < ActiveRecord::Migration
  def self.up
    Organisation.find_by_sql("SELECT " +
        "U.id person_id, " +
        "O_Agency.id agency_id " +
      "from " +
        "people U, " +
        "role_applications RA, " +
        "roles R, " +
        "organisations O_Agency " +
      "where " +
        "O_Agency.id = R.agency_id and " +
        "R.id = RA.role_id and " +
        "RA.person_id = U.id and " +
        "U.person_type_id = 1 and " + 
        "O_Agency.type_id = 1").each do |person_to_organisation|
        
          PersonToOrganisation.new do |link|
            link.person_id = person_to_organisation.person_id
            link.organisation_id = person_to_organisation.agency_id
            link.save
          end
          
      end
  end

  def self.down
  end
end
