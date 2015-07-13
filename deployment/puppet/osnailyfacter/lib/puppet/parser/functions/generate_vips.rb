require 'puppetx/l23_network_scheme'
require 'puppetx/l23_hash_tools'

module Puppet::Parser::Functions
  newfunction(:generate_vips) do |arguments|
    network_metadata =  arguments.first
    raise Puppet::ParseError, 'No network_metadata!' unless network_metadata.is_a? Hash
    raise 'L23network config is not prepared!' unless L23network::Scheme.has_config?

    vips = network_metadata.fetch 'vips', {}

    vips.each do |name, parameters|
      role = parameters['network_role']
      next unless role
      vip = {}

      vip['nic'] = function_get_network_role_property [role, 'interface']
      vip['base_veth'] = "#{vip['nic']}-hapr"
      vip['ns_veth'] = "hapr-#{name}"
      vip['ip'] = parameters['ipaddr']
      vip['cidr_netmask'] = function_netmask_to_cidr [ function_get_network_role_property [role, 'netmask'] ]
      vip['bridge'] = vip['nic']

      vip['namespace'] = parameters['namespace'] if parameters['namespace']
      vip['gateway'] = parameters['gateway'] if parameters['gateway']
      vip['gateway_metric'] = parameters['gateway_metric'] if parameters['gateway_metric']

      next unless vip['nic'] and vip['base_veth'] and vip['ns_veth'] and vip['ip']
      debug "Create VIP '#{name}': '#{vip.inspect}'"
      function_create_resources [ 'cluster::virtual_ip', { name => { 'vip' => vip } } ]
    end

  end
end
