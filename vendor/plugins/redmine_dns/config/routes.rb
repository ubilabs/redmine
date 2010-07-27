ActionController::Routing::Routes.draw do |map|
  map.with_options :controller => 'dns_provider' do |provider|
    provider.connect 'dns/provider/:action/:id'
  end
  map.with_options :controller => 'dns_settings' do |settings|
    settings.connect 'dns/settings/:action/:id'
  end
  map.with_options :controller => 'dns_template' do |template|
    template.connect 'dns/template/:action/:id'
  end
  map.with_options :controller => 'dns_snapshot' do |snapshot|
    snapshot.connect 'dns/snapshot/:action/:id'
  end
end