require 'ipaddr'

module Puppet::Parser::Functions
  newfunction(:get_connector_address, :type => :rvalue, :doc => <<-EOS
    This function returns STT connector addres based on 
    Nicira controllers addresses
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
    storage_net = IPAddr.new("#{node_data['storage_address']}/#{node_data['storage_netmask']}")
    internal_net = IPAddr.new("#{node_data['internal_address']}/#{node_data['internal_netmask']}")
    public_net = IPAddr.new("#{node_data['public_address']}/#{node_data['public_netmask']}") 
    nicira_controller = IPAddr.new(argv[0]['nsx_plugin']['nvp_controllers'].split(',')[0])
    if storage_net.include?(nicira_controller)
      return node_data['storage_address']
    else 
      if internal_net.include?(nicira_controller) 
        return node_data['internal_address']
      else public_net.include?(nicira_controller)
        return node_data['public_address']
      end 
    end
    return ""
  end
end
