require 'puppetx/l23_network_scheme'
require 'puppetx/l23_hash_tools'

module Puppet::Parser::Functions
  newfunction(:generate_vips) do
    network_metadata = function_hiera_hash ['network_metadata']
    raise Puppet::ParseError, 'Missing or incorrect network_metadata in Hiera!' unless network_metadata.is_a? Hash
    this_node_role = function_hiera ['role']
    raise Puppet::ParseError, "Could not get this node's role from Hiera!" if this_node_role.empty?

    default_node_roles = %w(controller primary-controller)

    # prepare network configuration if it was not prepared
    unless L23network::Scheme.has_config?
      network_scheme   = function_hiera_hash ['network_scheme']
      raise Puppet::ParseError, 'Missing or incorrect network_scheme in Hiera!' unless network_scheme.is_a? Hash
      function_prepare_network_config [ network_scheme ]
    end

    vips = network_metadata.fetch 'vips', {}

    vips.each do |name, parameters|
      network_role = parameters['network_role']

      # skip vip without network role defined
      next unless network_role
      node_roles = parameters.fetch 'node_roles', default_node_roles

      # skip vip if vip is not enables on thie node
      next unless node_roles.include? this_node_role

      # create a hash of vip parameters
      vip = {}
      vip['nic'] = function_get_network_role_property [network_role, 'interface']
      vip['base_veth'] = "#{vip['nic']}-hapr"
      vip['ns_veth'] = "hapr-#{name}"
      vip['ip'] = parameters['ipaddr']
      vip['cidr_netmask'] = function_netmask_to_cidr [ function_get_network_role_property [network_role, 'netmask'] ]
      vip['bridge'] = vip['nic']

      vip['namespace'] = parameters['namespace'] if parameters['namespace']
      vip['gateway'] = parameters['gateway'] if parameters['gateway']
      vip['gateway_metric'] = parameters['gateway_metric'] if parameters['gateway_metric']

      # skip vip without mandatory data fields
      unless vip['nic'] and vip['base_veth'] and vip['ns_veth'] and vip['ip']
        warn "Skipping incorrect VIP '#{name}': '#{vip.inspect}'"
        next
      end

      debug "Create VIP '#{name}': '#{vip.inspect}'"
      function_create_resources [ 'cluster::virtual_ip', { name => { 'vip' => vip } } ]
    end

  end
end
