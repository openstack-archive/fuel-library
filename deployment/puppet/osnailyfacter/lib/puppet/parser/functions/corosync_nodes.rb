module Puppet::Parser::Functions
  newfunction(:corosync_nodes, :type => :rvalue, :doc => <<-EOS
Return the hash of node names and their network_role IP addresses
to be used in pcmk_nodes resource.
  EOS
  ) do |args|
    error_msg = "corosync_nodes($nodes_hash, 'role')"
    nodes, network_role = args
    raise(Puppet::ParseError, "#{error_msg}: 1st argument should be a hash") if !nodes.is_a?(Hash)
    raise(Puppet::ParseError, "#{error_msg}: 2nd argument should be an a network-role name") if !network_role.is_a?(String)
    corosync_nodes = {}
    nodes.each do |node, metadata|
      fqdn = metadata['fqdn']
      uid = metadata['uid']
      ip = metadata['network_roles'][network_role]
      next unless fqdn and uid and ip
      corosync_nodes[fqdn] = {
          'id' => uid,
          'ip' => ip,
      }
    end
    corosync_nodes
  end
end

# vim: set ts=2 sw=2 et :
