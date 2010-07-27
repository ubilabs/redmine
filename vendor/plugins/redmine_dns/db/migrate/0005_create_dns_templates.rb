class CreateDnsTemplates < ActiveRecord::Migration
  def self.up
    create_table :dns_templates do |t|
      t.column :name, :string
      t.column :desc, :text
      t.column :records, :text
    end
  end

  def self.down
    drop_table :dns_templates
  end
end
