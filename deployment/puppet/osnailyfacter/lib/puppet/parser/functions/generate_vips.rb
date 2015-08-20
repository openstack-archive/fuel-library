require 'yaml'
require 'puppetx/l23_network_scheme'
require 'puppetx/l23_hash_tools'

module Puppet::Parser::Functions
  newfunction(:generate_vips) do |args|
    debug 'Call: generate_vips'

    network_metadata = function_hiera_hash ['network_metadata']
    raise Puppet::ParseError, 'Missing or incorrect network_metadata in Hiera!' unless network_metadata.is_a? Hash

    this_node_role = function_hiera ['role']
    raise Puppet::ParseError, "Could not get this node's role from Hiera!" if this_node_role.empty?

    network_scheme   = function_hiera_hash ['network_scheme']
    raise Puppet::ParseError, 'Missing or incorrect network_scheme in Hiera!' unless network_scheme.is_a? Hash

    default_node_roles = %w(controller primary-controller)

    unless L23network::Scheme.has_config?
      debug 'Running "prepare_network_config"'
      function_prepare_network_config [ network_scheme ]
    end

    vips = network_metadata.fetch 'vips', {}

    debug "VIPS structure: #{vips.to_yaml.gsub('!ruby/sym ','')}"

    vips.each do |name, parameters|

      debug "Processing VIP: '#{name}' with parameters: #{parameters.inspect}"
      network_role = parameters['network_role']

      unless network_role
        debug "Skipping vip: '#{name}' because it's 'network_role' parameter is not defined!"
        next
      end
      node_roles = parameters.fetch 'node_roles', default_node_roles

      unless node_roles.include? this_node_role
        debug "Skipping vip: '#{name}' because it's 'node_roles' parameter doesn't include this node's role: #{this_node_role}!"
        next
      end

      # create a hash of vip parameters
      vip = {}

      short_name = name[0,13]  # 13 here because max. interface name length in linus == 15 and two-letters prefix used
      base_veth = "v_#{short_name}"
      ns_veth = "b_#{short_name}"

      interface = function_get_network_role_property [network_role, 'interface']
      netmask = function_get_network_role_property [network_role, 'netmask']
      cidr_netmask = function_netmask_to_cidr [netmask]

      vip['base_veth'] = base_veth
      vip['ns_veth'] = ns_veth
      vip['ip'] = parameters['ipaddr']
      vip['cidr_netmask'] = cidr_netmask
      vip['bridge'] = interface

      vip['gateway'] = parameters['gateway'] if parameters['gateway']
      vip['gateway_metric'] = parameters['gateway_metric'] if parameters['gateway_metric']

      vip['namespace'] = parameters['namespace'] if parameters['namespace']
      vip['colocation_before'] = parameters['colocation_before'] if parameters['colocation_before']
      vip['colocation_after'] = parameters['colocation_after'] if parameters['colocation_after']

      # TODO: get_network_role_property should support gateway and metric
      # gateway = function_get_network_role_property [network_role, 'gateway']
      # gateway_metric = function_get_network_role_property [network_role, 'gateway_metric']

      gateway = network_scheme.fetch('endpoints', {}).fetch(vip['bridge'], {}).fetch('gateway', nil) unless vip['gateway']

      if gateway
        if name.include? 'vrouter'
          gateway_metric = '0'
        else
          gateway_metric = '10'
        end
      end

      # TODO: this should go from parameters instead of hardcoding
      if name.include? 'vrouter_pub'
        vip['ns_iptables_start_rules'] = "iptables -t nat -A POSTROUTING -o #{ns_veth} -j MASQUERADE"
        vip['ns_iptables_stop_rules'] = "iptables -t nat -D POSTROUTING -o #{ns_veth} -j MASQUERADE"
        # i'm running before the vip named 'vrouter' because vip 'vrouter' depends on me
        vip['colocation_before'] = 'vrouter' if vips.keys.include? 'vrouter'
      end

      vip['gateway'] = gateway || 'none'
      vip['gateway_metric'] = gateway_metric || '0'

      # skip vip without mandatory data fields
      unless vip['bridge'] and vip['base_veth'] and vip['ns_veth'] and vip['ip']
        warn "Skipping incorrect VIP '#{name}': '#{vip.to_yaml.gsub('!ruby/sym ','')}'"
        next
      end

      debug "Create VIP '#{name}': '#{vip.to_yaml.gsub('!ruby/sym ','')}'"
      function_create_resources [ 'cluster::virtual_ip', { name => { 'vip' => vip } } ]
    end

  end
end
