class CreateDnsProviders < ActiveRecord::Migration
  def self.up
    create_table :dns_providers do |t|
      t.column :name, :string
      t.column :type, :string, :limit => 30
      t.column :desc, :string
      t.column :username, :string
      t.column :password, :string
      t.column :enabled, :integer
    end
  end

  def self.down
    drop_table :dns_providers
  end
end
