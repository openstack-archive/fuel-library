module Puppet::Parser::Functions
  newfunction(:get_node_to_ipaddr_map_by_network_role, :type => :rvalue, :arity => 2, :doc => <<-EOS
Return a hash of nodes (node names are keys) that have one of the given roles.
example:
  get_node_to_ipaddr_map_by_network_role($nodes_hash, 'role')
EOS
  ) do |args|
    nodes, role = args

    raise(Puppet::ParseError, "1st argument should be a hash") unless nodes.is_a?(Hash)
    raise(Puppet::ParseError, "2nd argument should be a network-role name") unless role.is_a?(String)

    nodes = nodes['nodes'] if nodes.key?('nodes')

    nodes.values.reduce({}) do |result, node|
      net_role = node['network_roles'][role] rescue nil
      net_role.nil? ? result : result.merge(node['name'] => net_role.gsub(/\/\d+$/, ''))
    end
  end
end

