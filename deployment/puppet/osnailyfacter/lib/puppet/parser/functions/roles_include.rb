module Puppet::Parser::Functions
  newfunction(
      :roles_include,
      :type => :rvalue,
      :arity => 1,
      :doc => <<-EOS
Check if this node's roles include these roles.
EOS
  ) do |args|
    raise Puppet::ParseError, 'Only one argument with role or array of roles should be provided!' if args.size != 1
    intended_roles = args.first
    intended_roles = [intended_roles] unless intended_roles.is_a? Array
    if Puppet.version.to_f >= 4.0
      network_metadata = call_function 'hiera_hash', 'network_metadata'
    else
      network_metadata = function_hiera_hash ['network_metadata']
    end
    Puppet::Parser::Functions.autoloader.load :get_node_key_name unless Puppet::Parser::Functions.autoloader.loaded? :get_node_key_name
    node_name = function_get_node_key_name([])
    node_roles = network_metadata.fetch('nodes', {}).fetch(node_name, {}).fetch('node_roles', [])

    (node_roles & intended_roles).any?
  end
end
