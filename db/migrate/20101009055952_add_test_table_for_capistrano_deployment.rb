class AddTestTableForCapistranoDeployment < ActiveRecord::Migration
  def self.up
    create_table :test_capistrano do |t|
      t.column :subject, :string
      t.column :person_name, :string
      t.column :recipients, :string
      t.column :sender, :string
      t.timestamps
    end
  end

  def self.down
    drop_table :test_capistrano
  end
end
