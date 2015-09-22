require 'ipaddr'

Puppet::Parser::Functions::newfunction(:get_routable_networks_for_network_role, :type => :rvalue, :doc => <<-EOS
Return sorted list of networks for given network role.
example:
  get_routable_networks_for_network_role($network_scheme, 'network/role', 'non_obligatory_separator')

  If separater given, function should return string, instead list
EOS
  ) do |args|
    errmsg = "get_routable_networks_for_network_role($network_scheme, 'network/role')"
    net_scheme, net_role, separ = args
    raise(Puppet::ParseError, "#{errmsg}: 1st argument should be a hash") if !net_scheme.is_a?(Hash)
    raise(Puppet::ParseError, "#{errmsg}: 2nd argument should be an a network-role name") if !net_role.is_a?(String)
    rv = []
    e_point_name = net_scheme['roles'][net_role]
    return [] if e_point_name.nil?
    e_point = net_scheme['endpoints'][e_point_name]
    return [] if e_point.nil? or !e_point.is_a?(Hash)
    #collect subnets for aliases
    e_point['IP'].each do |cidr|
      masklen = cidr.split('/')[-1]
      ipa = IPAddr.new(cidr)
      rv << "#{ipa.to_s}/#{masklen}"
    end
    #collect subnets for routes if exists
    if e_point['routes'].is_a?(Array)
      e_point['routes'].each do |rou|
        rv << rou['net']
      end
    end
    rv = rv.sort
    if ! separ.nil?
      rv = rv.join(separ.to_s)
    end
    return rv
  end

# vim: set ts=2 sw=2 et :