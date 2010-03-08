class DnsProviderController < ApplicationController
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

  def commit
    params.each do |k,v|
      m = /^rr(\d+)/.match(k)
      puts "Got RR from entry: #{v}" unless (m.nil? || v.blank?)
      m = /^tmpl(\d+)/.match(k)
      puts "Got RR from template: #{v}" unless (m.nil? || v.blank?)
    end
    #TODO: call Provider.commit(filtered_records...)
    
    render(:update) do |page|
      page << "Element.setStyle('td_commit', {backgroundColor: 'green'});"
    end
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
    puts "GOT domain #{params[:domain]} with type #{params[:domain].class}"
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

    #TODO:save record in cache
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
      raw = r.gsub(/#\{\s*(\w+)\s*\}/) { zone_name }
      parts = raw.split()
      r = DnsRecord.new(:rrid => 'tmpl'+idx.to_s, :source => parts[0], :ttl => parts[1],
                        :rrtype => parts[3], :target => parts.slice(4, parts.length-4).join(" "))
      @records.push(r)
      @zone = DnsZone.new(:name =>zone_name, :soattl =>3600) #fake zone
    end
    render :partial => 'records'
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
