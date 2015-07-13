require 'puppetx/l23_network_scheme'
require 'puppetx/l23_hash_tools'

module Puppet::Parser::Functions
  newfunction(:generate_vips) do |arguments|
    network_metadata =  arguments.first
    raise Puppet::ParseError, 'No network_metadata!' unless network_metadata.is_a? Hash
    raise 'L23network config is not prepared!' unless L23network::Scheme.has_config?

    vips = network_mhie etadata.fetch 'vips', {}

    vips.each do |name, parameters|
      name = 'mgmt' if name == 'management'

      vip = {}
      vip['namespace'] = parameters['namespace']
      vip['nic'] = function_get_network_role_property ["#{name}/vip", 'interface']
      vip['base_veth'] = "#{vip['nic']}-hapr"
      vip['ns_veth'] = "hapr-#{name}"
      vip['ip'] = parameters['ipaddr']
      vip['cidr_netmask'] = function_get_network_role_property ["#{name}/vip", 'netmask']
      vip['bridge'] = vip['nic']
      vip['gateway'] = parameters['gateway']
      vip['gateway_metric'] = parameters['gateway_metric']
      next unless vip['nic'] and vip['base_veth'] and vip['ns_veth'] and vip['ip']
      function_create_resources ['cluster::virtual_ip', { 'vip' => vip }]
    end

  end
end
