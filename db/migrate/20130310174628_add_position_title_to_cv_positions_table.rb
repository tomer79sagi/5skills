class AddPositionTitleToCvPositionsTable < ActiveRecord::Migration
  def self.up
    add_column :fs2_cv_positions, :title, :text
  end

  def self.down
    remove_column :fs2_cv_positions, :title
  end
end
