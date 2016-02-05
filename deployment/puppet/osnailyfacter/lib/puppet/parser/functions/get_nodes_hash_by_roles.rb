module Puppet::Parser::Functions
  newfunction(:get_nodes_hash_by_roles, :type => :rvalue, :doc => <<-EOS
Return a hash of nodes (node names are keys) that have one of the given node roles.
example:
  get_nodes_hash_by_roles($network_metadata_hash, ['node_role1','node_role2'])
EOS
  ) do |args|
    errmsg = "get_nodes_hash_by_roles($network_metadata_hash, ['node_role1','node_role2'])"
    n_metadata, roles = args
    raise(Puppet::ParseError, "#{errmsg}: 1st argument should be a hash, but got: #{n_metadata.inspect}") if !n_metadata.is_a?(Hash)
    raise(Puppet::ParseError, "#{errmsg}: 1st argument should be a valid network_metadata hash, but got: #{n_metadata.inspect}") if !n_metadata.has_key?('nodes')
    raise(Puppet::ParseError, "#{errmsg}: 2nd argument should be an list of node roles, but got: #{roles.inspect}") if !roles.is_a?(Array)
    nodes = n_metadata['nodes']
    # Using unrequired node_property bellow -- is a workaround for ruby 1.8
    nodes.reject do |node_name, node_property|
      (roles & node_property['node_roles']).empty?
    end
  end
end

# vim: set ts=2 sw=2 et :
