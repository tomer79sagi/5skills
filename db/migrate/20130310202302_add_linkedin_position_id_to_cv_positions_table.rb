class AddLinkedinPositionIdToCvPositionsTable < ActiveRecord::Migration
  def self.up
    add_column :fs2_cv_positions, :linkedin_position_id, :int
  end

  def self.down
    remove_column :fs2_cv_positions, :linkedin_position_id
  end
end
