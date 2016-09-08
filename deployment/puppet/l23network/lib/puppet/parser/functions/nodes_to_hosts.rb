module Puppet::Parser::Functions
  newfunction(:nodes_to_hosts, :type => :rvalue, :doc => <<-EOS
              convert nodes array passed from Astute into
              hash for puppet `host` create_resources call
    EOS
  ) do |args|
    hosts=Hash.new
    nodes=args[0]
    nodes.each do |node|
      hosts[node['fqdn']]={:ip=>node['internal_address'],:host_aliases=>[node['name']]}
      notice("Generating host entry #{node['name']} #{node['internal_address']} #{node['fqdn']}")
    end
    return hosts
  end
end

# vim: set ts=2 sw=2 et :
