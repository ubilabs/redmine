require 'redmine'

Redmine::Plugin.register :redmine_dns do
  name 'Redmine Dns plugin'
  author 'Paul Kölle'
  description 'Manage DNS from redmine'
  version '0.0.2'

  menu( :admin_menu,
        :dns_provider, {
          :controller => 'dns/provider',
          :action => 'index' },
        :caption => 'DNS management'
      )
end
