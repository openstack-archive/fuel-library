require_relative '../../../puppetx/l23_network_scheme'

Puppet::Parser::Functions::newfunction(:get_dpdk_interfaces, :type => :rvalue, :doc => <<-EOS
    This function gets list of interfaces and returns bus_info addresses and
    intended drivers for dpdk transformations.
    ex: get_dpdk_interfaces() => [["0000:01:00.0", "igb_uio"]]
    EOS
  ) do |args|
  cfg = L23network::Scheme.get_config(lookupvar('l3_fqdn_hostname'))
  return [] unless cfg

  dpdk_interfaces = {}
  cfg[:interfaces].each do |if_name, if_data|
    vendor_specific = if_data[:vendor_specific] || {}
    bus_info = vendor_specific[:bus_info]
    dpdk_driver = vendor_specific[:dpdk_driver]
    dpdk_interfaces[bus_info] = dpdk_driver if bus_info && dpdk_driver
  end
  dpdk_interfaces.sort
end

# vim: set ts=2 sw=2 et :
