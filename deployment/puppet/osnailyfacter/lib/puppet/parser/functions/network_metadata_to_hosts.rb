#
# network_metadata_to_hosts
#

module Puppet::Parser::Functions
  newfunction(:network_metadata_to_hosts, :type => :rvalue, :doc => <<-EOS
              convert network_metadata hash to
              hash for puppet `host` create_resources call
    EOS
  ) do |args|
    hosts=Hash.new
    nodes=args[0].fetch('nodes', {})
    nodes.each do |name, props|
      hosts[props['fqdn']]={:ip=>props['network_roles']['mgmt/vip'],:host_aliases=>[name]}
      notice("Generating host entry #{name} #{props['network_roles']['mgmt/vip']} #{props['fqdn']}")
    end
    return hosts
  end
end

# vim: set ts=2 sw=2 et :