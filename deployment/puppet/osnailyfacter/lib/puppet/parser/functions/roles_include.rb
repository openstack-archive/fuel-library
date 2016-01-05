module Puppet::Parser::Functions
  newfunction(
      :roles_include,
      :type => :rvalue,
      :arity => 1,
      :doc => <<-EOS
Check if this node's roles include this role
EOS
  ) do |arguments|
    raise Puppet::ParseError, 'No roles provided!' if arguments.size < 1
    intended_roles = arguments.first
    intended_roles = [intended_roles] unless intended_roles.is_a? Array
    network_metadata = function_hiera_hash ['network_metadata']
    node_name = function_get_node_name []
    node_roles = network_metadata.fetch('nodes', {}).fetch(node_name, {}).fetch('node_roles', [])

    (node_roles & intended_roles).any?
  end
end
