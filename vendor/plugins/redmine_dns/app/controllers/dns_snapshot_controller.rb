class DnsSnapshotController < DnsController
  unloadable
  
  layout 'admin'
  before_filter :require_admin


  def create
    zone_name = params[:zone]
    provider = params[:provider]
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
    @snap = DnsSnapshot.new(:zone => zone_name, :records => rrs, :provider_id => provider,
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

  def restore
    if params[:commit] == "Cancel"
      redirect_to :controller => :dns_settings, :action => :index
    else
      provider = DnsProvider.find(params[:provider])
      snap = DnsSnapshot.find_by_zone(params[:zone])
      provider.commit(params[:zone], snap.records)
      redirect_to :controller => :dns_settings, :action => :index
    end
  end
end
