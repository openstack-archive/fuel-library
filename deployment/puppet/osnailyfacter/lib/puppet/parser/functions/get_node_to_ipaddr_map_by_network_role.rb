module Puppet::Parser::Functions
  newfunction(:get_node_to_ipaddr_map_by_network_role, :type => :rvalue, :doc => <<-EOS
Return a hash of nodes (node names are keys) that have one of the given roles.
example:
  get_node_to_ipaddr_map_by_network_role($nodes_hash, 'role')
EOS
  ) do |args|
    errmsg = "get_node_to_ipaddr_map_by_network_role($nodes_hash, 'role')"
    nodes, role = args
    raise(Puppet::ParseError, "#{errmsg}: 1st argument should be a hash") if !nodes.is_a?(Hash)
    raise(Puppet::ParseError, "#{errmsg}: 2nd argument should be an a network-role name") if !role.is_a?(String)
    nodes = nodes['nodes'] if nodes.has_key?('nodes')
    rv = {}
    nodes.each do |node_name, node_props|
      next if ! node_props.is_a?(Hash)
      n = node_props['network_roles']
      next if ! n.is_a?(Hash)
      rv[node_name] = n[role].gsub(/\/\d+$/,'') if n[role] != nil
    end
    return rv
  end
end

# vim: set ts=2 sw=2 et :