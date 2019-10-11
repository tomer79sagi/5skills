class CreateCustomTypesTable < ActiveRecord::Migration
  def self.up
    create_table :custom_types do |custom_types|
      
      # type_id > 1 = Job Source
      custom_types.column :type_id, :int
      
      custom_types.column :user_id, :int
      
      # ID for drop-down lists, initially will be negative index
      # If it's converted in the future to a shared index, it will become positive
      custom_types.column :select_id, :int
      
      custom_types.column :select_value, :string
      
      custom_types.timestamps
    end
  end

  def self.down
    drop_table :custom_types
  end
end
