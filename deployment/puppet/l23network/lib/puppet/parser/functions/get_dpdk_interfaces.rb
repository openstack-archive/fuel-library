require 'puppetx/l23_network_scheme'

Puppet::Parser::Functions::newfunction(:get_dpdk_interfaces, :type => :rvalue, :doc => <<-EOS
    This function gets list of interfaces and port transformations and
    returns bus_info addresses and intended drivers for dpdk transformations.
    ex: get_dpdk_interfaces() => [["0000:01:00.0", "igb_uio"]]
    EOS
  ) do |args|
  dpdk_interfaces = {}

  cfg = L23network::Scheme.get_config(lookupvar('l3_fqdn_hostname'))
  return [] unless cfg

  interfaces = cfg[:interfaces]
  cfg[:transformations].each do |transform|
    next unless transform[:name] ||\
         transform[:provider].to_s.upcase == "DPDKOVS" ||\
         transform[:action] == "add-port"

    if_name = transform[:name].to_sym
    bus_info = interfaces[if_name][:vendor_specific][:bus_info] if interfaces.has_key?(if_name)
    dpdk_driver = transform[:vendor_specific][:dpdk_driver] if transform[:vendor_specific]
    dpdk_interfaces[bus_info] = dpdk_driver if bus_info and dpdk_driver
  end

  dpdk_interfaces.sort
end

# vim: set ts=2 sw=2 et :
