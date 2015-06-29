module Puppet::Parser::Functions
  newfunction(:get_nodes_hash_by_roles, :type => :rvalue, :doc => <<-EOS
Return a hash of nodes (node names are keys) that have one of the given roles.
example:
  get_nodes_hash_by_roles($network_metadata_hash, ['role1','role2'])
EOS
  ) do |args|
    errmsg = "get_nodes_hash_by_roles($network_metadata_hash, ['role1','role2'])"
    n_metadata, roles = args
    raise(Puppet::ParseError, "#{errmsg}: 1st argument should be a hash") if !n_metadata.is_a?(Hash)
    raise(Puppet::ParseError, "#{errmsg}: 1st argument should be a valid network_metadata hash") if !n_metadata.has_key?('nodes')
    raise(Puppet::ParseError, "#{errmsg}: 2nd argument should be an list of roles") if !roles.is_a?(Array)
    nodes = n_metadata['nodes']
    nodes.reject do |node_name|
      (roles & nodes[node_name]['roles']).empty?
    end
  end
end

# vim: set ts=2 sw=2 et :