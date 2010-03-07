require 'net/http'
require 'uri'
require 'optparse'

module ActiveResource
  module Formats

  end
end

class DopolyResource < ActiveResource::Base
  self.site = "https://api.1api.net/api/ext/xdns.cgi"
  @command = ''

  def self.command
      puts "command accessed"
    return
  end

  def self.command=(name)
    puts "command= called"
  end
  
    # Builds the query string for the request.
  def self.query_string(options)
    qs = "?command=#{@command}"
    qs += "&#{options.to_query}" unless options.nil? || options.empty?
    return qs
  end

  def self.collection_path(prefix_options, query_options)
    prefix_options, query_options = split_options(prefix_options) if query_options.nil?
    return query_string(query_options)
  end
end

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

