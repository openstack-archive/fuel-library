require 'ipaddr'
begin
  require 'puppet/parser/functions/lib/prepare_cidr.rb'
rescue LoadError => e
  # puppet apply does not add module lib directories to the $LOAD_PATH (See
  # #4248). It should (in the future) but for the time being we need to be
  # defensive which is what this rescue block is doing.
  rb_file = File.join(File.dirname(__FILE__),'lib','prepare_cidr.rb')
  load rb_file if File.exists?(rb_file) or raise e
end
require 'puppetx/l23_network_scheme'

Puppet::Parser::Functions::newfunction(:get_network_role_property, :type => :rvalue, :doc => <<-EOS
    This function get get network the network_role name and mode --
    and return information about network role.

    ex: get_network_role_property('admin', 'interface')

    You can use following modes:
      interface -- network interface for the network_role
      ipaddr -- IP address for the network_role
      cidr -- CIDR-notated IP addr and mask for the network_role
      netmask -- string, contains dotted nemmask
      ipaddr_netmask_pair -- list of ipaddr and netmask
      phys_dev -- physical device name mapped to the network with the selected network_role

    Returns NIL if role not found.

    EOS
  ) do |argv|
  if argv.size == 2
    mode = argv[1].to_s().upcase()
  else
      raise(Puppet::ParseError, "get_network_role_property(...): Wrong number of arguments.")
  end

  cfg = L23network::Scheme.get_config(lookupvar('l3_fqdn_hostname'))
  #File.open("/tmp/L23network_scheme.yaml", 'w'){ |file| file.write cfg.to_yaml() }
  if cfg.nil?
    raise(Puppet::ParseError, "get_network_role_property(...): You must call prepare_network_config(...) first!")
  end

  network_role = argv[0].to_sym()

  if !cfg[:roles] || !cfg[:endpoints] || cfg[:roles].class.to_s() != "Hash" || cfg[:endpoints].class.to_s() != "Hash"
      raise(Puppet::ParseError, "get_network_role_property(...): Invalid cfg_hash format.")
  end

  # search interface for role
  interface = cfg[:roles][network_role]
  if !interface
      #raise(Puppet::ParseError, "get_network_role_property(...): Undefined network_role '#{network_role}'.")
      Puppet::debug("get_network_role_property(...): Undefined network_role '#{network_role}'.")
      return nil
  end

  # get endpoint configuration hash for interface
  ep = cfg[:endpoints][interface.to_sym()]
  if !ep
      Puppet::debug("get_network_role_property(...): Can't find interface '#{interface}' in endpoints for network_role '#{network_role}'.")
      return nil
  end

  if mode == 'INTERFACE'
    return interface.to_s
  end

  case ep[:IP].class().to_s
    when "Array"
      ipaddr_cidr = ep[:IP][0] ? ep[:IP][0] : nil
    when "String"
      Puppet::debug("get_network_role_property(...): Can't determine dynamic or empty IP address for endpoint '#{interface}' (#{ep[:IP]}).")
      if mode != 'PHYS_DEV'
        return nil
      end
    when "NilClass"
      ipaddr_cidr = nil
    else
      Puppet::debug("get_network_role_property(...): invalid IP address for endpoint '#{interface}'.")
      return nil
  end

  rv = nil
  case mode
    when 'CIDR'
      rv = ipaddr_cidr
    when 'NETMASK'
      rv = (ipaddr_cidr.nil?  ?  nil  :  IPAddr.new('255.255.255.255').mask(prepare_cidr(ipaddr_cidr)[1]).to_s)
    when 'IPADDR'
      rv = (ipaddr_cidr.nil?  ?  nil  :  prepare_cidr(ipaddr_cidr)[0].to_s)
    when 'IPADDR_NETMASK_PAIR'
      rv = (ipaddr_cidr.nil?  ?  [nil,nil]  :  [prepare_cidr(ipaddr_cidr)[0].to_s, IPAddr.new('255.255.255.255').mask(prepare_cidr(ipaddr_cidr)[1]).to_s])
    when 'PHYS_DEV'
      rv = L23network.get_phys_dev_by_transformation(interface, lookupvar('l3_fqdn_hostname'))
  end

  rv
end

# vim: set ts=2 sw=2 et :
