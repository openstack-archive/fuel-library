#
# array_or_string_to_array.rb
#

module Puppet::Parser::Functions
  newfunction(:nodes_hash_to_hosts, :type => :rvalue, :doc => <<-EOS
              convert nodes hash into hash for
              puppet `host` create_resources call
    EOS
  ) do |args|
    raise(Puppet::ParseError, "nodes_hash_to_hosts() should got 5 arguments. (#{args.length} given).") if args.length != 5
    hosts={}
    nodes=args[0]
    network_role=args[1]
    aliases=args[2]
    name_prefix=args[3]
    name_suffix=args[4]
    nodes.each do |name, node|
      ip = node['network_roles'][network_role]
      next if ! ip
      node_aliases = ( aliases  ?  ["#{name_prefix}#{node['name']}#{name_suffix}"]  :  [] )
      node_name = "#{name_prefix}#{node['fqdn']}#{name_suffix}"
      hosts[node_name] = { :ip => ip }
      hosts[node_name][:host_aliases] = node_aliases if ! node_aliases.empty?
      notice("Generating host entry #{node_name} #{ip} #{node_aliases.join(', ')}")
    end
    return hosts
  end
end

# vim: set ts=2 sw=2 et :
