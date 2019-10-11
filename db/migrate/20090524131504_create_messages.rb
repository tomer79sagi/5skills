class CreateMessages < ActiveRecord::Migration
  def self.up
    create_table :messages do |t|
      t.column :subject, :string
      t.column :person_name, :string
      t.column :recipients, :string
      t.column :sender, :string
      t.timestamps
    end
  end

  def self.down
    drop_table :messages
  end
end
