class CreatePeople < ActiveRecord::Migration
  def self.up
    create_table :people do |t|
      t.column :first_name, :string
      t.column :last_name, :string
      t.column :password, :string
      t.timestamps
    end
  end

  def self.down
    drop_table :people
  end
end