class CreateEmailConfirmations < ActiveRecord::Migration
  def self.up
    create_table :email_confirmations do |t|
      t.column :person_id, :int
      t.column :confirmation_string, :string
      t.timestamps
    end
  end

  def self.down
    drop_table :email_confirmations
  end
end
