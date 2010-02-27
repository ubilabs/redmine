class DnsZone < ActiveRecord::Base
  belongs_to :dns_provider

  def self.columns()
    @columns ||= []
  end

  def self.table_name
    self.name.tableize
  end

  def self.column(name, sql_type=nil, default=nil, null=true)
    columns << ActiveRecord::ConnectionAdapters::Column.new(name.to_s, default, sql_type.to_s, null)
  end

  def save(validate = true)
    validate ? valid? : true
  end

  column :updateddate, :string
  column :soarefresh, :integer
  column :soattl, :integer
  column :soaminttl, :integer
  column :createddate, :string
  column :soaretry, :integer
  column :soaexpire, :integer
  column :soarname, :string
  column :status, :string
  column :rrstotal, :integer
  column :soamname, :string
  column :wwwtargetdata, :string
  column :wwwtargettype, :string
  
end
