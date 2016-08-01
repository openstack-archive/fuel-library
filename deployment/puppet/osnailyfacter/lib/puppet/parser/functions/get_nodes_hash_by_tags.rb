module Puppet::Parser::Functions
  newfunction(:get_nodes_hash_by_tags, :type => :rvalue, :doc => <<-EOS
Return a hash of nodes (node names are keys) that have one of the given node tags.
example:
  get_nodes_hash_by_tags($network_metadata_hash, ['node_tag1','node_tag2'])
EOS
  ) do |args|
    errmsg = "get_nodes_hash_by_tags($network_metadata_hash, ['node_tag1','node_tag2'])"
    n_metadata, tags = args
    raise(Puppet::ParseError, "#{errmsg}: 1st argument should be a hash") if !n_metadata.is_a?(Hash)
    raise(Puppet::ParseError, "#{errmsg}: 1st argument should be a valid network_metadata hash") if !n_metadata.has_key?('nodes')
    raise(Puppet::ParseError, "#{errmsg}: 2nd argument should be an list of node tags") if !tags.is_a?(Array)
    nodes = n_metadata['nodes']
    # Using unrequired node_property bellow -- is a workaround for ruby 1.8
    nodes.reject do |node_name, node_property|
      (tags & node_property.fetch('node_tags', [])).empty?
    end
  end
end

# vim: set ts=2 sw=2 et :
