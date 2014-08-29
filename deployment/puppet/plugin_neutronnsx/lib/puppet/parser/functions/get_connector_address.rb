require 'ipaddr'

module Puppet::Parser::Functions
  newfunction(:get_connector_address, :type => :rvalue, :doc => <<-EOS
    This function returns STT connector address based on
    NSX controllers addresses
    EOS
  ) do |argv|
    if argv.size != 1
      raise(Puppet::ParseError, "get_connector_address(hash): Wrong number of arguments.")
    end
    node_data = {}
    argv[0]['nodes'].each do |node|
      if node['fqdn'] == argv[0]['fqdn']
        node_data = node
        break
      end
    end
    if node_data == {}
       raise(Puppet::ParseError, "Node not found in nodes Hash")
    end
    storage_net = IPAddr.new("#{node_data['storage_address']}/#{node_data['storage_netmask']}")
    internal_net = IPAddr.new("#{node_data['internal_address']}/#{node_data['internal_netmask']}")
    nsx_controller = IPAddr.new(argv[0]['nsx_plugin']['nsx_controllers'].split(',')[0])
    if storage_net.include?(nsx_controller)
      return node_data['storage_address']
    end
    if internal_net.include?(nsx_controller)
      return node_data['internal_address']
    end
    return node_data['public_address'].to_s
  end
end
