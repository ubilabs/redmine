class DnsProviderController < DnsController
  unloadable
  
  layout 'admin'
  before_filter :require_admin


  def index
    @providers = DnsProvider.providers()
    if @providers.length == 1 #preseed the next select
      @provider = @providers[0]
      @domains = @provider.get_zones({})
    elsif
      @providers.length == 0
      redirect_to :controller => "dns_settings"
    end
    #render :action => 'index'
  end

  def select_provider
    @providers = DnsProvider.providers()
    if params[:provider] && params[:zone]
      @provider = DnsProvider.find(params[:provider])
      @domains = @provider.get_zones({})
      render :action => 'index'
    end
  end

  def select_domain
    @provider = DnsProvider.find(params[:provider])
    #puts "GOT domain #{params[:domain]} with type #{params[:domain].class}"
    render :text => "" and return if params[:domain].blank?
    @zone = @provider.get_zone_status(params[:domain])
    @records = @provider.get_zone_records(params[:domain])
    @length = @records.length
    render :partial => 'zone_status'
  end

  def del_record
    @zone = params[:domain]
    id, data = params[:input].split('=')
    render(:update) do |page|
      page << "Element.setStyle('td_commit', {backgroundColor: 'red'});"
      page.remove('row_'+id)
    end
  end

  def new_record
    @provider = DnsProvider.find(params[:provider])
    @zone = @provider.get_zone_status(params[:domain])
    id, data = params[:input].split('=')
    count = id.slice(2, id.length)
    
    record = validate_raw_recorddata(id, data)
    render(:update) do |page|
      errmsg = "<div id='rr_errors'><p>"+@errors.collect { |attr,msg| "#{attr} - #{msg}" }.join("<br/>")+"</p>"
      page.replace('rr_errors', "<div id=\"rr_errors\">#{errmsg}</div>" )
    end and return unless record

    render(:update) do |page|
      page << "Element.setStyle('td_commit', {backgroundColor: 'red'});"
      page.replace("row_"+id, :partial => 'records', :locals => {:records => [record]})
      page.insert_html( :bottom, 'records_table', :partial => 'empty_record',
          :locals => { :count => (count.to_i+1).to_s})
    end
  end

  def load_template
    zone_name = params[:zone]
    render :text => ""  and return if params[:rr_template].blank?
    template = DnsTemplate.find(params[:rr_template])
    @records = []
    template.records.each_with_index do |r,idx|
      source = r.source.gsub(/#\{\s*(\w+)\s*\}/) { zone_name }
      r = DnsRecord.new(:rrid => 'tmpl'+idx.to_s, :source => source, :ttl => r.ttl,
                        :rrtype => r.rrtype, :target => r.target)
      @records.push(r)
      @zone = DnsZone.new(:name =>zone_name, :soattl =>3600) #fake zone
    end
    render :partial => 'records'
  end

  def commit
    zone_name = params[:zone]
    provider_id = params[:provider]

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
      
      m = /^tmpl(\d+)/.match(k)
      unless (m.nil? || v.blank?)
        record = validate_raw_recorddata('rr'+id.to_s, v)
        rrs.push(record) and id += 1 if record #TODO: if record is nil there was an error
        next
      end
      #puts "Got other parameter: #{k} -> #{v}" if (m.nil?)
    end

    #puts "DEBUG: record for commit #{rrs.inspect}"
    provider = DnsProvider.find(provider_id)
    if provider
      rrs.sort!
      provider.commit(zone_name, rrs)
    else
      #TODO: errors
    end

    render(:update) do |page|
      page << "Element.setStyle('td_commit', {backgroundColor: 'white'});"
    end
  end
end
