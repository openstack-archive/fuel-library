module Puppet::Parser::Functions
  newfunction(:corosync_nodes, :type => :rvalue, :doc => <<-EOS
Return the hash of controller names and their internal IP addresses
to be used in pcmk_nodes resource.
  EOS
  ) do |args|
    nodes = args[0]
    roles = args[1] || %w(primary-controller controller)
    fail "You should provided 'nodes' structure!" unless nodes.is_a? Array and nodes.any?
    corosync_nodes = {}
    nodes.each do |node|
      fqdn = node['fqdn']
      ip = node['internal_address']
      uid = node['uid']
      role = node['role']
      next unless roles.include? role
      next unless ip and fqdn
      corosync_nodes[fqdn] = {
          'id' => uid,
          'ip' => ip,
      }
    end
    corosync_nodes
  end
end

# vim: set ts=2 sw=2 et :
