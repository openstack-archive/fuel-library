#
# network_metadata_to_hosts
#

module Puppet::Parser::Functions
  newfunction(:network_metadata_to_hosts, :type => :rvalue, :arity => -2, :doc => <<-EOS
              convert network_metadata hash to
              hash for puppet `host` create_resources call

              Call network_metadata_to_hosts(network_metadata, 'network/role', 'optional_prefix')
    EOS
  ) do |args|

    required_opts = args[1] && (args[2] || false)

    raise(
      ArgumentError,
      'network_metadata_to_hosts(): `network_role` and `node_prefix` opts are required'
    ) if required_opts == false

    nodes = args[0].fetch('nodes', {})
    network_role = args[1] || 'mgmt/vip'
    prefix = args[2] || ''

    hosts = Hash.new

    nodes.each_value do |node|
      fqdn = "#{prefix}#{node['fqdn']}"
      hosts[fqdn] = {
        :ip           => node['network_roles'][network_role],
        :host_aliases => ["#{prefix}#{node['name']}"]
      }
      notice("Generating host entry #{node['name']} #{node['network_roles'][network_role]} #{node['fqdn']}")
    end

    hosts
  end
end

# vim: set ts=2 sw=2 et :
