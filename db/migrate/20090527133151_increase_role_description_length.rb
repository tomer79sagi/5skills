class IncreaseRoleDescriptionLength < ActiveRecord::Migration
  def self.up
    # Can't get this to work! :-(
    #execute "ALTER TABLE `testdb1_development`.`roles` MODIFY COLUMN `description` VARCHAR(4096) CHARACTER SET utf8 COLLATE utf8_general_ci DEFAULT NULL;"  
  end

  def self.down
    #execute "ALTER table customer modify Addr varchar(255)"
  end
end
