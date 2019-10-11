class ModifyActivityTable < ActiveRecord::Migration
  def self.up
    rename_column :activities, :parameters, :parameter_ids
    add_column :activities, :parameter_names, :string
    rename_column :activities, :friendly_names, :parameter_values
  end

  def self.down
    rename_column :activities, :parameter_ids, :parameters
    remove_column :activities, :parameter_names
    rename_column :activities, :parameter_values, :friendly_names
  end
end
