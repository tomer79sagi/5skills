class CreateRoles < ActiveRecord::Migration
  def self.up
    create_table :roles do |t|
      t.column :title, :string
      t.column :description, :string
      t.column :reference, :string
      t.column :close_date, :date
      t.column :role_application_id, :int
      t.timestamps
    end
  end

  def self.down
    drop_table :roles
  end
end
