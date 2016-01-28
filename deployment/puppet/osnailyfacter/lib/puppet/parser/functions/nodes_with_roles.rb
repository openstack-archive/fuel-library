module Puppet::Parser::Functions
  newfunction(:nodes_with_roles, :type => :rvalue, :doc => <<-EOS
Return a list of nodes that have one of the given roles, ex:
  nodes_with_roles(['primary-controller', 'controller'])
  nodes_with_roles(['primary-controller', 'controller', 'ceph-mon'], 'name')

If attr is defined, returns just that attribute for each node
instead of the whole node hash.
EOS
  ) do |args|
    raise Puppet::ParseError, 'Only one or 2 arguments allowed.' if args.size < 1 or args.size > 2
    roles, attr = args
    raise Puppet::ParseError, 'Roles should be provided as array' if ! roles.is_a?(Array)
    raise Puppet::ParseError, 'Attribute "name" should be provided as string' if ! (attr.is_a?(String) or attr == nil)
    n_metadata = function_hiera_hash(['network_metadata', {}])
    n_metadata.fetch('nodes', {}).select {|k,v|
      (roles & v.fetch('node_roles',[])).any?
    }.map {|k,v|
      attr ? v[attr] : v
    }
  end
end
# vim: set ts=2 sw=2 et :