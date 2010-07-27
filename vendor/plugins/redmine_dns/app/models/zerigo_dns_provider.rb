class ZerigoDnsProvider < DnsProvider

  validates_presence_of :name, :username, :password
  validates_uniqueness_of :username

  def api_url()
    return "http://ns.zerigo.com/api/1.1/"
  end

  def get_domains()

  end

  def get_zones()

  end

  def get_zone_status()

  end

  def get_records(zone)

  end

  def add_record(zone, params)

  end

  def del_record(zone, params)

  end
end
