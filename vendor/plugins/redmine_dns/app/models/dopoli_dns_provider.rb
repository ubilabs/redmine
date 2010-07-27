require 'net/http'
require 'net/https'
require 'openssl'

#hack Net:HTTP to support cipher selection
module Net
    class HTTP
        def set_context=(value)
            @ssl_context = OpenSSL::SSL::SSLContext.new(value)
        end
        if RUBY_VERSION =~ /^1\.8/
            ssl_context_accessor :ciphers
        end
    end
end

class DopoliDnsProvider < DnsProvider
  unloadable
  
  validates_presence_of :name, :username, :password
  validates_uniqueness_of :username

  #cache network access
  @@records = Hash.new
  @@zones = Array.new
  @@zone_status = Hash.new

  def credentials()
    return {'s_login' => self.username,'s_pw' => self.password }
  end

  def api_url()
    #return "https://api.1api.net/api/ext/xdns.cgi"
    return "https://api.domainreselling.de/api/call.cgi"
  end

  def get_zones(params)
    # params: {:userdepth=>'ALL', :limit=>nil, :domain=>nil, :dnszone=>nil}
    unless params[:dnszone].nil? || params[:dnszone][-1].chr == '.'
      params[:dnszone] = params[:dnszone]+"."
    end
    return @@zones[:data] unless @@zones.empty? #FIXME: cache timeout...

    userdepth = params[:userdepth] || 'ALL'
    params.update({'command'=>'QueryDNSZoneList', 'userdepth' => userdepth})
    ret = self.call_remote(params)
    ret = ret.fetch("DNSZONE", [])
    unless ret.empty?
      @@zones  = {:ts => Time.new.to_i, :dirty => false, :data => ret }
    end
    return ret
  end

  def get_zone_records(zone)
    #check that zone ends with a dot
    zone = zone+"." unless zone[-1].chr == "."
    if @@records.has_key?(zone)
      age = Time.new.to_i - @@records[zone][:ts]
      state = @@records[zone][:dirty] ? 'changed' : 'unchanged'
      logger.info("Fetching #{state} records stored #{age} seconds ago from cache for zone #{zone}")
      return @@records[zone][:data] #FIXME: cache timeout...
    end

    #cache miss
    data = {'command' => 'QueryDNSZoneRRList','dnszone' => zone}
    ret = self.call_remote(data)
    return [] unless ret.has_key?("RR")

    records = Set.new
    ret["RR"].each do |v|
      key = v.keys[0]
      parts = v.values[0].split()

      next if parts[3] == 'SOA' #don't show SOA entry
      r = DnsRecord.new(:rrid => key, :source => parts[0], :ttl => parts[1],
            :rrtype => parts[3], :target => parts.slice(4, parts.length-4).join(" "))
      records.add(r)
    end
    records = records.to_a
    records.sort!
    
    @@records[zone] = {:ts => Time.new.to_i, :dirty => false,
                       :new => Set.new, :deleted => Set.new, :updated => Set.new, :data => records }
    logger.info("stored #{records.length} records in class var @@records")
    return records
	end

  def get_zone_status(zone)
    zone = zone+"." unless zone[-1].chr == "."
    if @@zone_status.has_key?(zone)
      return @@zone_status[zone] #FIXME: cache timeout...
    end
		data = {'command' => 'StatusDNSZone',
				'dnszone' => zone}
		ret = self.call_remote(data)
    if ret["CODE"][0].to_i == 545
      #"this is most likely an external domain, filling in fake info"
      return DnsZone.new(:soamname => 'EXTERNAL')
    end
    res = Hash.new
    ret.each do |k,v| res[k.downcase] = v[0] end
    res = res.reject{ |k,v| !DnsZone.column_names.include?(k) }
    res[:name] = zone
	  z = DnsZone.new(res)
    @@zone_status[zone] = z
    return z
	end

  def add_record(zone, params)
    rr = DnsRecord.new(params) #use AR validations    
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

  def commit(zone, records)
    # push ALL records via rrX syntax (thus rewriting the whole zone)...
    data = {'command' => 'UpdateDNSZone',
				'dnszone' => zone }
    records.each do |r| data[r.rrid] = "#{r}" end
    ret = self.call_remote(data)
    #FIXME: report errors if any (return value?, raise?)
    logger.info("Server response to commit() for zone #{zone}: #{ret.inspect}")

    #invalidate cache and refetch
    @@records.delete(zone)
    get_zone_records(zone)
    #FIXME: compare cache with records and raise error if they don't match
  end

  protected
  def parse_response(data)
    ret = Hash.new()
    re_prop = /PROPERTY\[(.*?)\]\[(.*?)\]/i

    for line in data
      kv = line.split('=', 2)
      if not kv.length == 2
        next
      end
      m = re_prop.match(line)
      if m
        key, idx = m.captures()
        if ret.has_key?(key)
          if key == "RR"
            ret[key].push({"rr"+idx => kv[1].strip()})
          else
            ret[key].push(kv[1].strip())
          end
        else
          if key == "RR"
            ret[key] = [{"rr"+idx => kv[1].strip()}]
          else
            ret[key] = [kv[1].strip()]
          end
        end
      else
        ret[kv[0]] = [kv[1].strip()]
      end
    end
    return ret
  end

  def call_remote(data)
    data.update(self.credentials)
    uri = URI.parse(self.api_url)
    params = data.collect{|k,v| "#{k}=#{v}" }.join("&")
    params = URI.encode(params)
    ca_cert = File.join(File.dirname(__FILE__), '../../config/ThawteCA.pem')
    begin
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_PEER
      cipher_set = OpenSSL::SSL::SSLContext.new(:SSLv3).ciphers
      http.set_context = :SSLv3
      http.ciphers = cipher_set
      http.ca_file = File.join(ca_cert)
      resp = http.get(uri.path+"?"+params)
    rescue Exception => e
      logger.error("error fetching from dopoli: #{e}")
      return Hash.new #return empty hash 
    end
    return parse_response(resp.body)
  end
end
