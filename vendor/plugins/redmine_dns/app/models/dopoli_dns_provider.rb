class DopoliDnsProvider < DnsProvider

  validates_presence_of :name, :username, :password
  validates_uniqueness_of :username

  #cache network access
  @@records = Hash.new
  @@domains = Array.new
  @@zones = Hash.new

  def credentials()
    return {'s_login' => self.username,'s_pw' => self.password }
  end

  def api_url()
    return "http://194.50.187.100/api/call.cgi"
  end

  def get_domains(params)
    # params: {:userdepth=>'ALL', :limit=>nil, :domain=>nil, :zone=>nil}
    # gah, more perl...
    userdepth = params[:userdepth] || 'ALL'
    limit = params[:limit] || nil
    domain = params[:domain] || nil
    zone = params[:zone] || nil

		data = {'command' => 'QueryDomainlist',
				'userdepth' => userdepth, 'limit' => limit,
				'domain' => domain, 'zone' => zone}
		ret = self.call_remote(data)

		return ret["DOMAIN"]
	end

  def get_zones(zone)
    zone = zone+"." unless zone[-1].chr == "."
		data = {'command' => 'QueryDNSZoneList',
				'dnszone' => zone}
		ret = self.call_remote(data)
		return ret
	end

  def get_zone_records(zone)
    #check that zone ends with a dot
    zone = zone+"." unless zone[-1].chr == "."
    if @@records.has_key?(zone)
      age = Time.new.to_i - @@records[zone][:ts]
      state = @@records[zone][:dirty] ? 'changed' : 'unchanged'
      logger.info("Fetching #{state} records stored #{age} seconds ago from cache for zone #{zone}")
      return @@records[zone][:data]
    end
		data = {'command' => 'QueryDNSZoneRRList','dnszone' => zone}
		ret = self.call_remote(data)
    return [] unless ret.has_key?("RR")

    records = Array.new
    ret["RR"].each do |r|
      parts = r.split()
      records.push(
          DnsRecord.new(:source => parts[0], :ttl => parts[1],
                        :rrtype => parts[3], :target => parts[4])
                    ) if parts.length == 5
    end
    @@records[zone] = {:ts => Time.new.to_i, :dirty => false, :data => records }
    logger.info("stored records in class var @@records")
    return records
	end

  def get_zone_status(zone)
    zone = zone+"." unless zone[-1].chr == "."
		data = {'command' => 'StatusDNSZone',
				'dnszone' => zone}
		ret = self.call_remote(data)
    if ret["CODE"][0].to_i == 545
      puts "this is an external domain, filling in fake info"
      return DnsZone.new(:soamname => 'EXTERNAL')
    end
    res = Hash.new
    ret.each do |k,v| res[k.downcase] = v[0] end
    res = res.reject{ |k,v| !DnsZone.column_names.include?(k) }
	  return DnsZone.new(res)
	end

  def add_record(zone, params)
    rr = DnsRecord.new(params) #use AR validations
    # @params {:source, :ttl, :rrtype, :target}

		#fex: ['foo.example.net.', 3600, 'A',  '123.123.123.123']
		resource = "#{rr.source} #{rr.ttl} IN #{rr.rrtype} #{rr.target}"
		data = {'command' => 'UpdateDNSZone',
			    'dnszone' => zone,
			    'addrr0' => resource }
		return self.call_remote(data)
	end

  def del_record(zone, params)
    rr = DnsRecord.new(params)
    resource = "#{rr.source} #{rr.ttl} IN #{rr.rrtype} #{rr.target}"
		data = {'command' => 'UpdateDNSZone',
				'dnszone' => zone,
				'delrr0' => resource }
		ret = self.call_remote(data)
  end

  protected
  def parse_response(data)
    ret = Hash.new()
    re_prop = /property\[(.*?)\]\[(.*?)\]/i

    for line in data
      kv = line.split('=', 2)
      if not kv.length == 2
        next
      end
      m = re_prop.match(line)
      if m
        key, idx = m.captures()
        if ret.has_key?(key)
          ret[key].push(kv[1].strip())
        else
          ret[key] = [kv[1].strip()]
        end
      else
        ret[kv[0]] = [kv[1].strip()]
      end
    end
    return ret
  end

	def call_remote(data)
    logger.debug("calling call_remote with data #{data}")
		data.update(self.credentials)
		begin
			res = Net::HTTP.post_form(URI.parse(self.api_url), data)
		rescue Exception => e
			logger.error("error fetching from dopoli #{e}")
		end
		return parse_response(res.body)
	end
end

