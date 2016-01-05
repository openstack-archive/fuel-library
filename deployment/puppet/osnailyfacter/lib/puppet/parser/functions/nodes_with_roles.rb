module Puppet::Parser::Functions
  newfunction(:nodes_with_roles, :type => :rvalue, :doc => <<-EOS
Return a list of nodes that have one of the given roles. If attr is defined,
return just that attribute for each node instead of the whole node hash.
EOS
  ) do |args|
    n_metadata, roles, attr = args
    n_metadata['nodes'].select {|k,v|
      (roles & v['node_roles']).any?
    }.map {|k,v|
      attr ? v[attr] : v
    }
  end
end

# vim: set ts=2 sw=2 et :
