#
# network_metadata_to_hosts
#

module Puppet::Parser::Functions
  newfunction(:network_metadata_to_hosts, :type => :rvalue, :doc => <<-EOS
              convert network_metadata hash to
              hash for puppet `host` create_resources call

              Call network_metadata_to_hosts(network_metadata, 'network/role', 'optional_prefix')
    EOS
  ) do |args|

    unless args.size == 1 or args.size == 3
      raise(Puppet::ParseError, 'network_metadata_to_hosts(): Wrong number of arguments, need one or three')
    end

    hosts = Hash.new
    nodes = args[0].fetch('nodes', {})
    network_role = (args[1].to_s == ''  ?  'mgmt/vip'  :  args[1].to_s)
    prefix = args[2].to_s
    nodes.each do |name, props|
      fqdn = "#{prefix}#{props['fqdn']}"
      hosts[fqdn]={:ip=>props['network_roles'][network_role],:host_aliases=>["#{prefix}#{props['name']}"]}
      notice("Generating host entry #{name} #{props['network_roles'][network_role]} #{props['fqdn']}")
    end
    return hosts
  end
end

# vim: set ts=2 sw=2 et :
