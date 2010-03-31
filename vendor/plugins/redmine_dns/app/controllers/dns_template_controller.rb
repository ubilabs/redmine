class DnsTemplateController < DnsController
  unloadable
  
  layout 'admin'
  before_filter :require_admin

  def new
    @tmpl = DnsTemplate.new
    @zone = DnsZone.new(:name =>'#{zone}', :soattl =>3600)
  end

  def create
    puts "GOT new template"
    unless params[:template].nil?
       # create a new array of DnsRecords to validate the data, new
      # rrid's are generated from rr0 to rrN
      id = 0; rrs = []
      params[:template].each do |k,v|
        m = /^rr(\d+)/.match(k)
        unless (m.nil? || v.blank?)
          record =  validate_raw_recorddata('rr'+id.to_s, v)
          rrs.push(record) and id += 1 if record #TODO: if record is nil there was an error
          next
        end
      end
    end
    @tmpl = DnsTemplate.create(
                :name => params["dns_template"]["name"],
                :desc => params["dns_template"]["desc"],
                :records => rrs)

    if @tmpl.valid?
      @tmpl.save!
      redirect_to :controller => :dns_settings, :action => :index
    else
      redirect_to :show
    end
  end

  def show
    @tmpl ||= DnsTemplate.find(params[:id])
    @tmpl.records.sort!
    @zone = DnsZone.new(:name =>'#{zone}', :soattl =>3600) 
  end

  def update
    @tmpl = DnsTemplate.find(params[:id])
    unless params[:template].nil?
      id = 0; rrs = []
      params[:template].each do |k,v|
        m = /^rr(\d+)/.match(k)
        unless (m.nil? || v.blank?)
          record =  validate_raw_recorddata('rr'+id.to_s, v)
          rrs.push(record) and id += 1 if record #TODO: if record is nil there was an error
          next
        end
      end
    end
    @tmpl.update_attributes({:records => rrs,
                             :name => params["dns_template"]["name"],
                             :desc => params["dns_template"]["desc"]})
    if @tmpl.valid?
      @tmpl.save!
      redirect_to :controller => :dns_settings, :action => :index
    else
      puts @tmpl.errors.inspect
      redirect_to :controller => :dns_settings, :action => :index
    end
  end

end