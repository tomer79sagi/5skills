class NewSchema < ActiveRecord::Migration
  def self.up
    # Add contact details fields to organisation
    add_column :organisations, :phone, :string
    add_column :organisations, :fax, :string
    add_column :organisations, :website, :string
    add_column :organisations, :email, :string
    
    add_column :people, :person_type_id, :int
    add_column :people, :phone_home, :string
    add_column :people, :phone_work, :string
    add_column :people, :fax, :string
    add_column :people, :mobile, :string
    add_column :people, :website, :string
    add_column :people, :organisation_id, :int # indicating agent -> agency or company contact -> company relationship
    
    add_column :roles, :company_contact_id, :int
    
    # finally, drop :contact_details table
    drop_table :contact_details
  end

  def self.down
    remove_column :organisations, :name
    remove_column :organisations, :fax
    remove_column :organisations, :website
    remove_column :organisations, :email
    
    remove_column :people, :person_type_id
    remove_column :people, :phone_home
    remove_column :people, :phone_work
    remove_column :people, :fax
    remove_column :people, :mobile
    remove_column :people, :website
    remove_column :people, :organisation_id
    
    remove_column :roles, :company_contact_id
    
    create_table :contact_details do |t|
      t.column :mobile, :string
      t.column :phone, :string
      t.column :fax, :string
      t.column :email, :string
      t.column :website, :string
      t.column :person_id, :int
      t.timestamps
    end    
  end
end
