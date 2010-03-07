module ApplicationHelper
  RRTYPES = ['A', 'AAAA', 'CNAME', 'NS', 'MX', 'TXT', 'SRV', 'SPF', 'X-HTTP', 'X-SMTP']
  
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
end
