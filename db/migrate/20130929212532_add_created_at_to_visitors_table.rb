class AddCreatedAtToVisitorsTable < ActiveRecord::Migration
  def self.up
    add_timestamps :fs2_visitors
  end

  def self.down
    remove_timestamps :fs2_visitors
  end
end
