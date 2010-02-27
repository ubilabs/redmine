require 'redmine'

Redmine::Plugin.register :redmine_dns do
  name 'Redmine Dns plugin'
  author 'Paul Kölle'
  description 'Manage DNS from redmine'
  version '0.0.1'

  menu( :admin_menu,
        :dns_provider, {
          :controller => 'dns_provider',
          :action => 'index' },
        :caption => 'DNS management'
      )

  permission(:add_dns_provider, :dns_provider => :add)
  permission(:delete_dns_provider, :dns_provider => :del)
  permission(:manage_dns_zones, :zone_controller => :manage)
end
