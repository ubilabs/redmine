module DnsProviderHelper
  RRTYPES = ['A', 'AAA', 'CNAME', 'NS', 'MX', 'TXT', 'SRV', 'SPF', 'X-HTTP-REDIRECT']

  def providers_for_select(providers)
    providers.each_with_index.collect do |i,v| "<option value=\"#{v+1}\">#{i.type}</option>" end
  end

  def domains_for_select(domains)
    res = domains.each.collect do |d| "<option value=\"#{d}\">#{d}</option>" end
    res.sort!
    res.insert(0, '<option value="">---</option>')
  end

  def rrtype_for_select(record)
    #puts "rrtype_for_select got #{record}, class #{record.class}"
    ret = Array.new
    RRTYPES.each do |rr|
      if record.rrtype == rr
        ret.push("<option value=\"#{rr}  selected=\"selected\">#{rr}</option>")
      else
        ret.push("<option value=\"#{rr}\">#{rr}</option>")
      end
    end
    return ret
  end

  def rrdata_for_input(record)
      return "#{record.source} #{record.ttl} IN #{record.rrtype} #{record.target}"
  end
end
