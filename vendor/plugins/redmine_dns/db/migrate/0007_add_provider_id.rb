class AddProviderId < ActiveRecord::Migration
  def self.up
    add_column :dns_snapshots, :provider_id, :integer
  end

  def self.down
    remove_column :dns_snapshots, :provider_id, :integer
  end
end