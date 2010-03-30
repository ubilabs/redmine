class CreateDnsSnapshots < ActiveRecord::Migration
  def self.up
    create_table :dns_snapshots do |t|
      t.column :name, :string
      t.column :zone, :string
      t.column :records, :text
      t.column :date, :date
    end
  end

  def self.down
    drop_table :dns_snapshots
  end
end
