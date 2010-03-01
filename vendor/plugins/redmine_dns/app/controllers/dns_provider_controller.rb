class DnsProviderController < ApplicationController
  unloadable
  
  layout 'admin'
  before_filter :require_admin


  def index
    @providers = DnsProvider.providers()
    if @providers.length == 1 #preseed the next select
      @provider = @providers[0]
      @domains = @provider.get_domains({})
    end
    render :action => 'index' unless request.xhr?
  end

  def select_provider
    @providers = DnsProvider.providers()
    if params[:provider] && params[:zone]
      @provider = DnsProvider.find(params[:provider])
      @domains = @provider.get_domains({})
      render :action => 'index' unless request.xhr?
    end
  end

  def select_domain
    @provider = DnsProvider.find(params[:provider])
    @zone = @provider.get_zone_status(params[:domain])
    @records = @provider.get_zone_records(params[:domain])
    #logger.debug("select_domain called with provider #{@provider} for zone #{@zone} with records #{@records}")
    render :partial => 'zone_status'
  end

  def del_record
    logger.info(params.to_json)
  end

  def save_record

  end

  def new_record

  end
end
