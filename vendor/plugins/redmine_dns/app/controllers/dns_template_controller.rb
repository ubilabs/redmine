class DnsTemplateController < ApplicationController
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
      records = []
      params[:template].collect do |k,v| records.push(v) unless (v.empty? ||v.nil?) end
    end
    @tmpl = DnsTemplate.create(
                :name => params["dns_template"]["name"],
                :desc => params["dns_template"]["desc"],
                :records => records)

    if @tmpl.valid?
      @tmpl.save!
      redirect_to :controller => :dns_settings, :action => :index
    else
      redirect_to :show
    end
  end

  def show
    @tmpl ||= DnsTemplate.find(params[:id])
    @zone = DnsZone.new(:name =>'#{zone}', :soattl =>3600)
    #FIXME: @tmpl.records is an array of strings but the template wants DnsRecords 
  end

  def update
    @tmpl = DnsTemplate.find(params[:id])
    unless params[:template].nil?
      records = []
      params[:template].collect do |k,v| records.push(v) unless (v.empty? ||v.nil?) end
    end
    @tmpl.update_attributes({:records => records,
                             :name => params[:name], :desc => params[:desc]})
    if @tmpl.valid?
      @tmpl.save!
      redirect_to :controller => :dns_settings, :action => :index
    else
      redirect_to :show
    end
  end
  
end