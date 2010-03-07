class DnsTemplate < ActiveRecord::Base
  validates_presence_of :name
  
  serialize :records, Array
end