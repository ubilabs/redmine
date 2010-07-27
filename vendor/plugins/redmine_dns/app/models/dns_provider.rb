class DnsProvider < ActiveRecord::Base

  validates_presence_of :name, :username, :password
  validates_uniqueness_of :username

  # hmm, this is just instances
  def self.providers()
    providers = DnsProvider.find(:all)
    return  providers if providers
    return nil
  end

  # find subclasses
  def self.inherited(cls)
    if @subclasses
			@subclasses << cls
		else
			@subclasses = [cls]
		end
	end

	def self.subclasses
		@subclasses
	end
end
