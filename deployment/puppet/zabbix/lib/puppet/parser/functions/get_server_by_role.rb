Puppet::Parser::Functions::newfunction(
    :get_server_by_role,
    :type => :rvalue,
    :doc => 'Returns server node hash by role'
) do |args|
  fuel_nodes = args[0]
  requested_roles = args[1]
  server = ""
  fuel_nodes.each do |node|
    next unless requested_roles.include?(node['role'])
    server = node
  end
  server
end

