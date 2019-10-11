class CreateEnumerations < ActiveRecord::Migration
  def self.up
    create_table :enumerations, :force => true do |t|
      t.column :severity, :enum, :limit => [:low, :medium, :high, :critical]
      t.column :color, :enum, :limit => [:red, :blue, :green, :yellow]
    end    
  end

  def self.down
    drop_table :enumerations
  end
end
