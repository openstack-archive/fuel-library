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
    nodes = function_hiera ['nodes']
    uid = function_hiera ['uid']

    nodes.any? do |node|
      next unless node['uid'] == uid
      next unless node['role']
      intended_roles.include? node['role']
    end
  end
end
