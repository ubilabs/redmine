class DnsTemplate < ActiveRecord::Base
  DnsRecord

  validates_presence_of :name
  
  serialize :records, Array
end