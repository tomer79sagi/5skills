class AddNewVisitorFieldToVisitorsTable < ActiveRecord::Migration
  def self.up
    add_column :fs2_visitors, :new_visitor, :boolean
  end

  def self.down
    remove_column :fs2_visitors, :new_visitor
  end
end
