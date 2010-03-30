class DnsSnapshot < ActiveRecord::Base
  validates_presence_of :name, :zone
  
  serialize :records, Array
end
