class DnsSettingsController < ApplicationController
  unloadable

  layout 'admin'
  before_filter :require_admin


  def index
    @providers = DnsProvider.find(:all)
    @templates = DnsTemplate.find(:all)

    #set up a fake zone for the template rows
    @zone = DnsZone.new(:name =>'#{zone}', :soattl =>3600)
  end


  def new_provider
    #let's cheat because DnsProvider.find(1).type.constantize.new() raises TypeError
    p = DopoliDnsProvider.new(:username => params[:login], :password => params[:password])
    if p.valid?
      p.save!
    end
    redirect_to :action => :index
  end

  def del_provider
      # later....
      redirect_to :action => :index
  end

  def new_template
    puts "GOT new template"
    unless params[:template].nil?
      records = []
      params[:template].collect do |k,v| records.push(v) unless (v.empty? ||v.nil?) end
    end
    template = DnsTemplate.create(
                :name => params["dns_template"]["name"],
                :desc => params["dns_template"]["desc"],
                :records => records)
    template.save!
    if template.valid?
      template.save!
      redirect_to :action => :index
    end
  end

  def del_template
    DnsTemplate.delete(params[:template])
    #redirect_to :action => :index
    render(:update) do |page|
      page.remove('template_row_'+params[:template])
    end
  end
end

