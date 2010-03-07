class DnsRecord < ActiveRecord::Base
  belongs_to :dns_zone


  validate do |record|
    #check emptiness..
    [:rrid, :source, :ttl, :rrtype, :target].each do |attr|
      record.errors.add(attr, "#{attr} can't be blank") if attr.blank?
    end

    #check :target wich depends on record.rrtype
    target_msg = case record.rrtype
    when 'A' then
      # check record.target for ipv4
     unless /\A(?:25[0-5]|(?:2[0-4]|1\d|[1-9])?\d)(?:\.(?:25[0-5]|(?:2[0-4]|1\d|[1-9])?\d)){3}\z/.match(record.target)
        "The target for an A record needs to be a valid IPv4 address."
     end
    when 'AAAA' then
      #check record.target for ipv6
    when 'CNAME' then
      #no useful checks here, perhaps check for !IP
    when 'MX' then
      #XXX check at least for priority and a hostname
    when 'TXT' then
      #XXX
    when 'X-HTTP' then
      match = /^(FRAME|REDIRECT)\s+https?:\/\/(.+)\.(.+)/.match(record.target.strip)
      unless match
        "X-HTTP takes the form of either 'FRAME' or 'REDIRECT' and an URL"
      end
    else
      record.errors.add(:rrtype, "Unknown RR type #{record.rrtype}.")
    end
    record.errors.add(:target, target_msg) unless target_msg.blank?

    #check numericallity of :ttl
    match = /^\d+$/.match(record.ttl)
    record.errors.add(:ttl, "TTL needs to be a number.") unless match
  end

  def self.columns()
    @columns ||= []
  end

  def self.table_name
    self.name.tableize
  end
  
  def self.column(name, sql_type=nil, default=nil, null=true)
    columns << ActiveRecord::ConnectionAdapters::Column.new(name.to_s, default, sql_type.to_s, null)
  end

  column :rrid, :string
  column :source, :string
  column :ttl, :string
  column :rrtype, :string
  column :target, :string

end
