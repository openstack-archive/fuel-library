#
# nodes_to_hosts.rb
#

module Puppet::Parser::Functions
  newfunction(:nodes_to_hosts, :type => :rvalue, :doc => <<-EOS
              convert nodes array passed from Astute into
              hash for puppet `host` create_resources call
    EOS
  ) do |args|

    hosts = {}
    return hosts if args.empty?

    nodes = args[0]
    raise(Puppet::ParseError, 'nodes_to_hosts(): Requires an array to work with') unless nodes.is_a?(Array)

    nodes.each do |node|
      hosts[node['fqdn']] = (node['role'] == '__VOID__') ?
        { :ensure => 'absent' } :
        { :ip => node['internal_address'], :host_aliases => [node['name']] }

      notice("Generating host entry #{node['name']} #{node['internal_address']} #{node['fqdn']}")
    end
    hosts
  end
end

# vim: set ts=2 sw=2 et :
