module DnsProviderHelper
  RRTYPES = ['A', 'AAAA', 'CNAME', 'NS', 'MX', 'TXT', 'SRV', 'SPF', 'X-HTTP', 'X-SMTP']

  def providers_for_select(providers)
    providers.each.collect do |p| "<option value=\"#{p.id}\">#{p.type} (#{p.username})</option>" end
  end

  def domains_for_select(domains)
    res = domains.each.collect do |d| "<option value=\"#{d}\">#{d}</option>" end
    res.sort!
    res.insert(0, '<option value="">---</option>')
  end

  def rrtype_for_select(record)
    #puts "rrtype_for_select got #{record}, class #{record.class}"
    res = Array.new
    RRTYPES.each do |rr|
      if record != nil && record.rrtype == rr
        res.push("<option value=\"#{rr}\"  selected=\"selected\">#{rr}</option>")
      else
        res.push("<option value=\"#{rr}\">#{rr}</option>")
      end
    end
    res.insert(0, '<option value="">---</option>')
    return res
  end

  def rrtemplate_for_select()
    res = Array.new
    DnsTemplate.find(:all).each do |t|
      res.push("<option value=\"#{t.id}\">#{t.name}</option>")
    end
    res.insert(0, '<option value="">---</option>')
    return res
  end

  def rrdata_for_input(record)
      return "#{record.source} #{record.ttl} IN #{record.rrtype} #{record.target}"
  end
end
