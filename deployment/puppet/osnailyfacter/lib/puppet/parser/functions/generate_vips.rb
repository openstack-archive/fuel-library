require 'yaml'
require 'digest'
require 'ipaddr'
require 'puppetx/l23_network_scheme'
require 'puppetx/l23_hash_tools'

module Puppet::Parser::Functions
  newfunction(
      :generate_vips,
      type: :rvalue,
      arity: -1,
      doc: <<-eof
Create Virtual IP Pacemaker resources from the networs scheme and metadata.
Returns a hash that can be fed to the create_resources function.
  eof
  ) do |args|
    debug 'Call: generate_vips'

    network_metadata = args[0]
    raise Puppet::ParseError, 'generate_vips(): Missing or incorrect network_metadata in Hiera!' unless network_metadata.is_a? Hash

    network_scheme = args[1]
    raise Puppet::ParseError, 'generate_vips(): Missing or incorrect network_scheme in Hiera!' unless network_scheme.is_a? Hash

    roles = args[2] || []
    raise Puppet::ParseError, "generate_vips(): Could not get this node's roles from Hiera!" if roles.empty?

    default_node_roles = %w(controller primary-controller)

    unless L23network::Scheme.has_config?
      debug 'Running "prepare_network_config"'
      function_prepare_network_config [ network_scheme ]
    end

    vips = network_metadata.fetch 'vips', {}

    debug "VIPS structure: #{vips.to_yaml.gsub('!ruby/sym ','')}"

    resources = {}

    vips.each do |name, parameters|

      debug "Processing VIP: '#{name}' with parameters: #{parameters.inspect}"

      # create a hash of vip parameters
      vip = {}

      if parameters['namespace']
        vip['ns'] = parameters['namespace']
      else
        warn "Skipping vip: '#{name}' because the 'namespace' parameter is not defined! Such VIPs are not managed by Pacemaker and should be handled by plugin completely."
        next
      end

      network_role = parameters['network_role']
      unless network_role
        debug "Skipping vip: '#{name}' because it's 'network_role' parameter is not defined!"
        next
      end

      node_roles = parameters.fetch 'node_roles', default_node_roles
      unless node_roles.any? { |node_role| roles.include? node_role }
        debug "Skipping vip: '#{name}' because it's 'node_roles' parameter doesn't include this node's roles: #{roles.join ', '}!"
        next
      end

      # 13 here because max. interface name length in linus == 15 and two-letters prefix used
      if name.length > 13
        short_name = name[0,8]
        name_hash = Digest::MD5.hexdigest name
        short_name += '_' + name_hash[0,4]
      else
        short_name = name[0,13]
      end

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

      vip['colocation_before'] = parameters['colocation_before'] if parameters['colocation_before']
      vip['colocation_after'] = parameters['colocation_after'] if parameters['colocation_after']

      # TODO: get_network_role_property should support gateway and metric
      # gateway = function_get_network_role_property [network_role, 'gateway']
      # gateway_metric = function_get_network_role_property [network_role, 'gateway_metric']

      gateway = nil
      gateway = network_scheme.fetch('endpoints', {}).fetch(vip['bridge'], {}).fetch('gateway', nil) unless vip['gateway']

      gateway_metric = nil
      if gateway
        if name.include? 'vrouter'
          gateway_metric = '0'
        else
          gateway_metric = '10'
        end
      end

      iptables_rules = nil
      iptables_rules = parameters['vendor_specific']['iptables_rules'] if parameters['vendor_specific'] and parameters['vendor_specific']['iptables_rules']

      if iptables_rules
         iptables_substitute_hash = {
             :INT => ns_veth,
             :IP => parameters['ipaddr'],
             :CIDR => "#{parameters['ipaddr']}/#{cidr_netmask}",
         }

         vip['ns_iptables_start_rules'] = iptables_rules['ns_start'].join('; ')
         vip['ns_iptables_stop_rules'] = iptables_rules['ns_stop'].join('; ')
         iptables_substitute_hash.each_pair { |k, v| vip['ns_iptables_start_rules'] = vip['ns_iptables_start_rules'].gsub("<%#{k.to_s}%>", v) }
         iptables_substitute_hash.each_pair { |k, v| vip['ns_iptables_stop_rules'] = vip['ns_iptables_stop_rules'].gsub("<%#{k.to_s}%>", v) }
      end

      vip['colocation_before'] = 'vrouter' if name.include? 'vrouter_pub' and vips.keys.include? 'vrouter'
      vip['gateway_metric'] = gateway_metric || '0'

      gateway = 'none' unless gateway

      begin
        gateway = IPAddr.new gateway unless %w(link none).include? gateway
        gateway = gateway.to_s
      rescue
        gateway = 'none'
      end

      vip['gateway'] = gateway

      # skip vip without mandatory data fields
      unless vip['bridge'] and vip['base_veth'] and vip['ns_veth'] and vip['ip']
        warn "Skipping incorrect VIP '#{name}': '#{vip.to_yaml.gsub('!ruby/sym ','')}'"
        next
      end

      debug "Create VIP '#{name}': '#{vip.to_yaml.gsub('!ruby/sym ','')}'"
      resources.store name, vip
    end

    resources
  end
end
