class RoleApplicationChanges < ActiveRecord::Migration
  def self.up
    # Changes to Roles Table
    add_column :roles, :agency_id, :int # Add 'organisation_id' link for the agency
    add_column :roles, :company_id, :int # Add 'organisation_id' link for the company
    add_column :roles, :agent_id, :int # Add 'agent_id' link (TODO: This will change to many later on)
    add_column :roles, :source_id, :int # Source comes out of enumeration (hard coded currently),
      # e.g. Seek, TradeMe etc
    add_column :roles, :type_id, :int # Type comes out of enumeration (hard coded currently),
      # e.g. Permanent, Contract etc
    
    # Changes to Contact Details Table
    # Have two columns: person_id and organisation_id. One of these will be blank for each record to allow
    # contact_details to be 'belongs_to' to both (hopefully it doesn't create constraints that will prevent
    # from this approach to work)
    add_column :contact_details, :organisation_id, :int
    
    # Changes to Organisation Table
    # from this approach to work)
    add_column :organisations, :type_id, :int # Enumeration of 'Agency', 'Company'    
  end

  def self.down
    remove_column :roles, :agency_id
    remove_column :roles, :company_id
    remove_column :roles, :agent_id
    remove_column :roles, :source_id
    remove_column :roles, :type_id
    remove_column :contact_details, :organisation_id
    remove_column :organisations, :type_id
  end
end
