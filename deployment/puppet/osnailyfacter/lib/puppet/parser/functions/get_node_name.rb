module Puppet::Parser::Functions
  newfunction(:get_node_name, :type => :rvalue, :doc => <<-EOS
Return a node short name
EOS
  ) do |args|
    fqdn = function_hiera ['fqdn', lookupvar('fqdn')]
    fqdn.split('.')[0]
  end
end

# vim: set ts=2 sw=2 et :