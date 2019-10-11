class CreatePersonToOrganisations < ActiveRecord::Migration
  def self.up
    create_table :person_to_organisations do |t|
      t.column :person_id, :int
      t.column :organisation_id, :int
      t.timestamps
      

    end
  end

  def self.down
    drop_table :person_to_organisations
  end
end
