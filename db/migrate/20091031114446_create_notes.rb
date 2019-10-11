class CreateNotes < ActiveRecord::Migration
  def self.up
    create_table :notes do |t|
      t.column :note_contents, :string
      t.timestamps
    end
  end

  def self.down
    drop_table :notes
  end
end
