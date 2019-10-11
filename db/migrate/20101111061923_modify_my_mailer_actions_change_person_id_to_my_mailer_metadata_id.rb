class ModifyMyMailerActionsChangePersonIdToMyMailerMetadataId < ActiveRecord::Migration
  def self.up
    rename_column :my_mailer_actions, :person_id, :my_mailer_metadata_id
  end

  def self.down
    rename_column :my_mailer_actions, :my_mailer_metadata_id, :person_id
  end
end
