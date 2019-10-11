class CreateMyMailerActionsTable < ActiveRecord::Migration
  def self.up
    create_table :my_mailer_actions do |actions|
      actions.column :person_id, :int
      actions.column :controller, :string
      actions.column :action, :string
      actions.column :parameter_ids, :string
      actions.column :parameter_names, :string
      actions.column :parameter_values, :string
      actions.column :email_action_key, :string
      
      actions.timestamps
    end
  end

  def self.down
    drop_table :my_mailer_actions
  end
end
