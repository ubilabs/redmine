class DnsProvider < ActiveRecord::Base
  has_many :zones

  validates_presence_of :name, :username, :password
  validates_uniqueness_of :username

  # enumerate all registered DnsSources
  def self.providers()
    providers = DnsProvider.find(:all)
    return  providers if providers
    return nil
  end
end
