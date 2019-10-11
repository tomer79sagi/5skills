class CreateFilesTable < ActiveRecord::Migration
  def self.up
    create_table :flyc_files do |files|
      
      files.column :name, :string
      files.column :mime_type, :string
      files.column :extension, :string
      files.column :size, :int
      files.column :path, :string
      files.column :uri, :string
      files.column :person_id, :int
      
      files.timestamps
    end
  end

  def self.down
    drop_table :flyc_files
  end
end
