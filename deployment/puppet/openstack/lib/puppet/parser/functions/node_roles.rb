Puppet::Parser::Functions::newfunction(
    :node_roles,
    :type => :rvalue,
    :doc => 'Get all roles of the given node. Args: nodes_hash, uid.'
) do |args|
  node  = args[0]
  uid   = args[1]
  roles = []
  node.each do |n|
    next unless n['role']
    next unless n['uid'] == uid
    roles << n['role'] unless roles.include? n['role']
  end
  roles
end