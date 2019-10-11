class CreateOrganisationTables < ActiveRecord::Migration
  def self.up
    create_table :fs2_organisations do |organisations|
      
      organisations.column :name, :string
      organisations.column :slogan, :string
      organisations.column :blurb, :string
      organisations.column :phone, :int
      organisations.column :email, :string
      organisations.column :website, :string
      organisations.column :organisation_type, :int # 1 = Agency, 2 = Company
      
      organisations.timestamps
    end
    
    create_table :fs2_contacts do |contacts|
      
      contacts.column :full_name, :string
      contacts.column :mobile_phone, :string
      contacts.column :work_phone, :string
      contacts.column :other_phone, :string      
      contacts.column :email, :string
      contacts.column :contact_type, :int # 1 = Agency, 2 = Company
      contacts.column :organisation_id, :int # 1 = Agency, 2 = Company
      
      contacts.timestamps
    end
    
    create_table :fs2_jobs do |jobs|
      
      jobs.column :title, :string
      jobs.column :description, :string
      jobs.column :responsibilities, :string
      jobs.column :skills_profile_id, :int
      jobs.column :company_id, :int
      jobs.column :company_contact_id, :int
      jobs.column :agency_id, :int
      jobs.column :agency_contact_id, :int
      
      jobs.timestamps
    end
    
    rename_column :fs2_files, :person_id, :entity_id
  end

  def self.down
    drop_table :fs2_organisations
    drop_table :fs2_contacts
    drop_table :fs2_jobs
    
    rename_column :fs2_files, :entity_id, :person_id 
  end
end
