module Puppet::Parser::Functions
  newfunction(:get_node_key_name, :type => :rvalue, :doc => <<-EOS
Return a node key name.
Key name is a immutable name, that used as key into network_metadata/nodes hash
EOS
  ) do |args|
    if Puppet.version.to_f >= 4.0
      uid = call_function 'hiera', 'uid'
    else
      uid = function_hiera ['uid']
    end
    raise Puppet::ParseError, 'Node UID not found.' if uid.nil?
    "node-#{uid}"
  end
end

# vim: set ts=2 sw=2 et :
