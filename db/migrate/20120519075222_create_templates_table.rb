class CreateTemplatesTable < ActiveRecord::Migration
  def self.up
    create_table :fs2_templates do |template|
      template.column :name, :string
      template.column :skills_profile_id, :int
    end
  end

  def self.down
    drop_table :templates
  end
end
