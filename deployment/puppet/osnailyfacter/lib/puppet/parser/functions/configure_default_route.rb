require 'ipaddr'
require 'pp'
require 'puppetx/l23network'

Puppet::Parser::Functions::newfunction(:configure_default_route, :type => :rvalue, :doc => <<-EOS
This function gets hash of network endpoints configuration and check if fw-admin endpoint has gateway
and any network includes management vrouter vip address. If yes - it removes it and set default route
to vip of vrouter via management network, if no - it does nothing.
EOS
) do |argv|
  raise Puppet::ParseError, 'configure_default_route(): Arguments: network_scheme, management_vrouter_vip, fw_admin_role, management_role' if argv.size != 4

  network_scheme = argv[0]
  management_vrouter_vip = argv[1]
  fw_admin_role = argv[2]
  management_role = argv[3]

  raise Puppet::ParseError, 'network_scheme is empty!' if network_scheme.nil?
  raise Puppet::ParseError, 'management_vrouter_vip is empty!' if management_vrouter_vip.nil?
  raise Puppet::ParseError, 'fw_admin_role is empty!' if fw_admin_role.nil?
  raise Puppet::ParseError, 'management_role is empty!' if management_role.nil?

  network_scheme = L23network.sanitize_keys_in_hash network_scheme
  network_scheme = L23network.sanitize_bool_in_hash network_scheme

  fw_admin_int = network_scheme[:roles][fw_admin_role.to_sym].to_sym
  management_int = network_scheme[:roles][management_role.to_sym].to_sym

  endpoints = network_scheme[:endpoints]

  change_to_vrouter = false

  endpoints[management_int][:IP].each do |ipnet|
      change_to_vrouter = true if endpoints[fw_admin_int][:gateway] and IPAddr.new(ipnet).include?(IPAddr.new(management_vrouter_vip))
  end

  unless change_to_vrouter
    debug 'configure_default_route(): Will not change the default route to the vrouter IP address'
    return {}
  end

  debug 'configure_default_route(): Change default route to vrouter ip address!'
  interface_names = [ fw_admin_int, management_int ]
  interface_names.each do |endpoint_name|
    next unless endpoints[endpoint_name]
    endpoints[endpoint_name].delete(:gateway) if ( endpoints[endpoint_name][:gateway] and endpoint_name == fw_admin_int )
    endpoints[endpoint_name][:gateway] = management_vrouter_vip if endpoint_name == management_int
  end
  network_scheme
end

# vim: set ts=2 sw=2 et :
