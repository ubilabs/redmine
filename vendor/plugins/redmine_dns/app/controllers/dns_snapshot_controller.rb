class DnsSnapshotController < ApplicationController
  unloadable
  
  layout 'admin'
  before_filter :require_admin


  def create
    zone_name = params[:zone]

    # create a new array of DnsRecords to validate the data, new
    # rrid's are generated from rr0 to rrN
    id = 0; rrs = []
    params.each do |k,v|
      m = /^rr(\d+)/.match(k)
      unless (m.nil? || v.blank?)
        record =  validate_raw_recorddata('rr'+id.to_s, v)
        rrs.push(record) and id += 1 if record #TODO: if record is nil there was an error
        next
      end
    end

    #FIXME: ask user for :name
    @snap = DnsSnapshot.new(:zone => zone_name, :records => rrs,
                            :date => DateTime.now, :name => "snapshot for #{zone_name}")

    if @snap.save!
      render(:update) do |page|
        page << "Element.setStyle('td_snapshot', {backgroundColor: 'green'});"
      end
    else
      #TODO: errors
    end
  end

  def show
    @snap = DnsSnapshot.find(params[:id])
    @snap.records.sort!
  end

  def save_or_restore
  
  end

  def validate_raw_recorddata(id, stringval)
    parts = stringval.nil? ? nil : stringval.split()
    if parts.nil? || parts.length < 5
      @errors = {:all => "Missing values..."}
      return nil
    end
    r = DnsRecord.new(:rrid => id, :source => parts[0], :ttl => parts[1],
                          :rrtype => parts[3], :target => parts.slice(4, parts.length-4).join(" "))
    unless r.valid? #this calls r.validate
      @errors = r.errors
      return nil
    end
    return r
  end
end
