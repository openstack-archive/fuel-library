module Puppet::Parser::Functions
  newfunction(:nodes_with_roles, :type => :rvalue, :doc => <<-EOS
Return a list of nodes that have one of the given roles. If attr is defined,
return just that attribute for each node instead of the whole node hash.
EOS
  ) do |args|
    nodes, roles, attr = args
    nodes.select {|node|
      roles.include? node['role']
    }.uniq {|node|
      node['uid']
    }.map {|node|
      attr ? node[attr] : node
    }
  end
end

# vim: set ts=2 sw=2 et :
