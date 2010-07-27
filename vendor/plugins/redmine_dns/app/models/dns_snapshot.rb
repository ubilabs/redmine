class DnsSnapshot < ActiveRecord::Base
  DnsRecord

  validates_presence_of :name, :zone
  
  serialize :records, Array
end
