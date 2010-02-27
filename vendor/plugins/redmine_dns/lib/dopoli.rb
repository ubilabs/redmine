require 'net/http'
require 'uri'
require 'optparse'

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
				ret[key].update({idx => kv[1].strip()})
			else
				ret[key] = {idx => kv[1].strip()}
			end
		else
			ret[kv[0]] = kv[1].strip()
		end
	end
	return ret
end

class Registrar
	@@baseurl = 'http://194.50.187.100/api/call.cgi'
	
	def initialize(username, password)
		@creds = {'s_login' => username,
				  's_pw' => password }
	end
	
	def getDomainList(userdepth='ALL', limit=nil, domain=nil, zone=nil)
		data = {'command' => 'QueryDomainlist',
				'userdepth' => userdepth, 'limit' => limit,
				'domain' => domain, 'zone' => zone}
		ret = self.callRemote(data)
		ret.each {|k, v| puts "#{k} => #{v}\n" }
	end
	
	def getZoneList(zone)
		data = {'command' => 'QueryDNSZoneList',
				'dnszone' => zone}
		ret = self.callRemote(data)
		ret.each {|k, v| puts "#{k} => #{v}\n" }
	end
	
	def getZoneRRList(zone)
		data = {'command' => 'QueryDNSZoneRRList',
				'dnszone' => zone}
		ret = self.callRemote(data)
		ret.each {|k, v| 
		  if k == 'RR'
				v.each{|e| puts "domain: #{e[1]}\n"}
				#v.each{|e| puts "debug: #{e.split}\n"}
		  else	
				puts "#{k} => #{v}\n";
		  end
			}
	end
	
	def getZoneStatus(zone)
		data = {'command' => 'StatusDNSZone',
				'dnszone' => zone}
		ret = self.callRemote(data)
		ret.each {|k, v| puts "#{k} => #{v}\n" }
	end
	
	def addDNSResource(zone, resource)
		#resource needs to be an array with [source, ttl, rrtype, target]
		#fex: ['foo.example.net.', 3600, 'A',  '123.123.123.123']
		resource = "%s %d IN %s %s" % resource
		data = {'command' => 'UpdateDNSZone',
			    'dnszone' => zone,
			    'addrr0' => resource }
		ret = self.callRemote(data)
	end
	
	def delDNSResource(zone, resource)
		resource = "%s %d IN %s %s" % resource
		data = {'command' => 'UpdateDNSZone',
				'dnszone' => zone,
				'delrr0' => resource }
		ret = self.callRemote(data)
	end
	
	protected
	def callRemote(data)
		data.update(@creds)
		begin
			res = Net::HTTP.post_form(URI.parse(@@baseurl), data)
		rescue Exception => e
			puts e
		end
		return parse_response(res.body)
		#ret.each {|k, v| puts "#{k} => #{v}\n" }
	end
end


if __FILE__ == $0
	options = {}
	OptionParser.new do |opts|
		opts.banner = "Example: domresell.rb -a add -d foo.net. -r 'one.foo.net 600 A 12.12.12.12'"
		opts.on('-d', '--domain DOMAIN', 'Domain to operate on.') do |d|
			if not /.*\.$/.match(d)
				d = d+'.'
			end
			options[:domain] = d
		end
		opts.on('-a', '--action ACTION', 'Action is "add" or "del" or "list"') do |a|
			options[:action] = a
		end
		opts.on('-r', '--resource RES', 'DNS resource to add or delete') do |r|
			#FIXME: catching errors
			res = r.split
		    res[1] = res[1].to_i
			options[:resource] = res
		end
	end.parse!
	
	r = Registrar.new( 'sumaato.net', 'LQDNCue6')
	if options[:action] == 'add'
		r.addDNSResource(options[:domain], options[:resource])
	elsif options[:action] == 'del'
		r.delDNSResource(options[:domain], options[:resource])
	elsif options[:action] == 'list'
		r.getZoneRRList(options[:domain])
	else
		puts "Unknown action #{options[:action]}"
	end
end
