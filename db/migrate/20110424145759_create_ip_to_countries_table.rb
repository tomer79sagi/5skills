class CreateIpToCountriesTable < ActiveRecord::Migration
  def self.up
    create_table :ip_to_countries do |ip_countries|
      ip_countries.column :ip_from, :double
      ip_countries.column :ip_to, :double
      ip_countries.column :registry, :string
      ip_countries.column :assigned, :int
      ip_countries.column :ctry, :string
      ip_countries.column :cntry, :string
      ip_countries.column :country, :string
      
      ip_countries.timestamps
    end
  end

  def self.down
    drop_table :ip_to_countries
  end
end
