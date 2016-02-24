module Puppet::Parser::Functions
  newfunction(:get_node_key_name, :type => :rvalue, :doc => <<-EOS
Return a node key name.
Key name is a immutable name, that used as key into network_metadata/nodes hash
EOS
  ) do |args|
    uid = function_hiera ['uid']
    raise Puppet::ParseError, 'Node not found.' if uid.nil?
    network_metadata = function_hiera_hash ['network_metadata']

    node = network_metadata['nodes'].detect {|k,n| n['uid'] == uid}
    raise Puppet::ParseError, 'Node not found.' if node.nil?
    node[0]
  end
end

# vim: set ts=2 sw=2 et :
