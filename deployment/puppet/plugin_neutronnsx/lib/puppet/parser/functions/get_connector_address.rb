require 'ipaddr'

module Puppet::Parser::Functions
  newfunction(:get_connector_address, :type => :rvalue, :doc => <<-EOS
    This function returns STT connector address based on
    NSX controllers addresses
    EOS
  ) do |argv|
    raise Puppet::ParseError, 'You should privide: nodes, fqdn, nsx_controllers!' unless argv.size == 3
    nodes = argv[0]
    fqdn = argv[1]
    nsx_controllers = argv[2]
    node_data = nodes.find { |node| node['fqdn'] == fqdn }
    raise Puppet::ParseError, 'Node not found in the nodes Hash!' unless node_data
    storage_net = IPAddr.new "#{node_data['storage_address']}/#{node_data['storage_netmask']}"
    internal_net = IPAddr.new "#{node_data['internal_address']}/#{node_data['internal_netmask']}"
    nsx_controller = IPAddr.new nsx_controllers.split(',').first
    if storage_net.include? nsx_controller
      node_data['storage_address'].to_s
    elsif internal_net.include? nsx_controller
      node_data['internal_address'].to_s
    else
      node_data['public_address'].to_s
    end
  end
end
