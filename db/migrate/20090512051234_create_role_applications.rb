class CreateRoleApplications < ActiveRecord::Migration
  def self.up
    create_table :role_applications do |t|
      t.column :person_id, :int
      t.timestamps
    end
  end

  def self.down
    drop_table :role_applications
  end
end
