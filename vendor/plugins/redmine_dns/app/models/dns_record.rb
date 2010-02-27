class DnsRecord < ActiveRecord::Base
  belongs_to :dns_zone

  def self.columns()
    @columns ||= []
  end

  def self.column(name, sql_type=nil, default=nil, null=true)
    columns << ActiveRecord::ConnectionAdapters::Column.new(name.to_s, default, sql_type.to_s, null)
  end

  column :source, :string
  column :ttl, :integer
  column :rrtype, :string
  column :target, :string

end
