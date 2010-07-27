module DnsSettingsHelper
  def providers_for_select(providers)
    DnsProvider.subclasses.each_with_index.collect do |v,i| "<option value=\"#{i+1}\">#{v}</option>" end
  end
end