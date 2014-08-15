# require 'ipaddr'
# require 'yaml'
# require 'json'

class MrntNeutronNR
  def initialize(scope, cfg)
    @scope = scope
    @neutron_config = cfg
    @tenant_name = nil
  end

  #class method
  def self.sanitize_array(aa)
    aa.reduce([]) do |rv, v|
      rv << case v.class
          when Hash  then sanitize_hash(v)
          when Array  then sanitize_array(v)
          else v
      end
    end
  end

  #class method
  def self.sanitize_hash(hh)
    rv = {}
    hh.each do |k, v|
      rv[k.to_sym] = case v.class.to_s
        when "Hash"  then sanitize_hash(v)
        when "Array" then sanitize_array(v)
        else v
      end
    end
    return rv
  end

  def default_netmask()
    "/24"
  end

  def get_tenant()
    # Returns @tenant_name, if defined
    # otherwise it checks @neutron_config structure, and return tenant name from there, if not nil
    # if tenant name is nil, or @neutron_config hash doesn't have one of the keys defined, then "admin" is returned
    @tenant_name = @tenant_name || @neutron_config[:predefined_routers][:router04][:tenant] || "admin" rescue "admin"
  end

  def get_default_router_config()
    Marshal.load(Marshal.dump({
      :name    => nil,
      :tenant  => get_tenant(),
      :int_subnets => nil,
      :ext_net     => nil,
    }))
  end

  def get_default_network_config()
    Marshal.load(Marshal.dump({
      :net => {
        :name         => nil,
        :tenant       => get_tenant(),
        :network_type => nil,
        :physnet      => nil,
        :router_ext   => nil,
        :shared       => nil,
        :segment_id   => nil,
      },
      :subnet => {
        :name    => nil,
        :tenant  => get_tenant(),
        :network => nil,  # Network id or name this subnet belongs to
        :cidr    => nil,  # CIDR of subnet to create
        :gateway => nil,
        :alloc_pool  => nil,  # Allocation pool IP addresses
        :nameservers => nil,  # DNS name servers used by hosts
        :enable_dhcp => false,
      },
    }))
  end

  def create_resources()
    res__neutron_net = 'neutron_net'
    res__neutron_net_type = Puppet::Type.type(res__neutron_net.downcase.to_sym)
    res__neutron_subnet = 'neutron_subnet'
    res__neutron_subnet_type = Puppet::Type.type(res__neutron_subnet.downcase.to_sym)
    res__neutron_router = 'neutron_router'
    res__neutron_router_type = Puppet::Type.type(res__neutron_router.downcase.to_sym)
    previous = nil
    segment_id = @neutron_config[:L2][:enable_tunneling]  ?  @neutron_config[:L2][:tunnel_id_ranges].split(':')[0].to_i  :  0
    @neutron_config[:predefined_networks].each do |net, ncfg|
      Puppet::debug("-*- processing net '#{net}': #{ncfg.to_yaml()}")
      # config network resources parameters
      network_config = get_default_network_config()
      network_config[:net][:name] = net.to_s
      network_config[:net][:tenant] =  get_tenant()
      network_config[:net][:router_ext] = ncfg[:L2][:router_ext]
      if network_config[:net][:router_ext]
        network_config[:net][:network_type] = 'local'
      else
        network_config[:net][:network_type] = ncfg[:L2][:network_type]
      end
      network_config[:net][:shared] = ncfg[:shared]
      network_config[:subnet][:name] = "#{net.to_s}__subnet"
      network_config[:subnet][:network] = network_config[:net][:name]
      network_config[:subnet][:cidr] = ncfg[:L3][:subnet]
      network_config[:subnet][:gateway] = ncfg[:L3][:gateway]
      network_config[:subnet][:nameservers] = ncfg[:L3][:nameservers]  ?  ncfg[:L3][:nameservers].join(' ')  :  nil
      network_config[:subnet][:enable_dhcp] = ncfg[:L3][:enable_dhcp]  ?  "True"  :  "False"
      if ncfg[:L3][:floating]
        floating_a = ncfg[:L3][:floating].split(/[\:\-]/)
        if floating_a.size != 2
          raise(Puppet::ParseError, "You must define floating range for network '#{net}' as pair of IP addresses, not a #{ncfg[:L3][:floating]}")
        end
        network_config[:subnet][:alloc_pool] = "start=#{floating_a[0]},end=#{floating_a[1]}"
        network_config[:subnet][:nameservers] = nil
        network_config[:subnet][:enable_dhcp] = "False"
      end
      network_config[:net][:physnet] = ncfg[:L2][:physnet]
      if network_config[:net][:network_type].downcase == 'gre'
        # Get first free segment_id for GRE
        network_config[:net][:segment_id] = ncfg[:L2][:segment_id]  ?  ncfg[:L2][:segment_id]  :  segment_id
        segment_id += 1
        network_config[:net][:physnet] = nil # do not pass this parameter in this segmentation type
      elsif network_config[:net][:network_type].downcase == 'local'
        network_config[:net][:physnet] = nil
        network_config[:net][:segment_id] = nil
      elsif network_config[:net][:network_type].downcase == 'vlan' && ncfg[:L2][:physnet]
        # Calculate segment_id for VLAN mode from personal physnet settings
        _physnet = ncfg[:L2][:physnet].to_sym
        _segment_id_range = @neutron_config[:L2][:phys_nets][_physnet][:vlan_range] || "4094:xxx"
        _segment_id = _segment_id_range.split(/[:\-]/)[0].to_i
        network_config[:net][:segment_id] = _segment_id
      elsif network_config[:net][:network_type].downcase == 'vlan'
        # vlan without physnet
        raise(Puppet::ParseError, "Unrecognized segmentation ID or VLAN range for net '#{net}', binding to '#{ncfg[:L2][:physnet]}'")
      #else # another network types -- do nothing...
      end
      Puppet::debug("-*- using segment_id='#{network_config[:net][:segment_id]}' for net '#{net}'")
      # create neutron_net resource
      p_res = Puppet::Parser::Resource.new(
        res__neutron_net,
        network_config[:net][:name].to_s,
        :scope => @scope,
        :source => res__neutron_net_type
      )
      p_res.set_parameter(:ensure, :present)
      previous && p_res.set_parameter(:require, [previous])
      network_config[:net].each do |k,v|
        v && p_res.set_parameter(k.to_sym, v)
      end
      @scope.compiler.add_resource(@scope, p_res)
      previous = p_res.to_s
      Puppet::debug("*** Resource '#{previous}' created succefful.")
      # create neutron_subnet resource
      p_res = Puppet::Parser::Resource.new(
        res__neutron_subnet,
        network_config[:subnet][:name].to_s,
        :scope => @scope,
        :source => res__neutron_subnet_type
      )
      p_res.set_parameter(:ensure, :present)
      p_res.set_parameter(:require, [previous])
      network_config[:subnet].each do |k,v|
        v && p_res.set_parameter(k.to_sym, v)
      end
      @scope.compiler.add_resource(@scope, p_res)
      previous = p_res.to_s
      Puppet::debug("*** Resource '#{previous}' created succefful.")
    end
    # create pre-defined routers
    if previous # if no networks -- we don't create any router
      @neutron_config[:predefined_routers].each do |rou, rcfg|
        next if rcfg[:virtual]
        # config router
        router_config = get_default_router_config()
        router_config[:name] = rou.to_s
        router_config[:tenant] = rcfg[:tenant]
        router_config[:ext_net] = rcfg[:external_network] #"rcfg[:external_network]__subnet"
        #todo: realize
        router_config[:int_subnets] = rcfg[:internal_networks].map{|x| "#{x}__subnet"}
        # create resource
        p_res = Puppet::Parser::Resource.new(
          res__neutron_router,
          router_config[:name].to_s,
          :scope => @scope,
          :source => res__neutron_router_type
        )
        p_res.set_parameter(:ensure, :present)
        p_res.set_parameter(:require, [previous])
        router_config.each do |k,v|
          v && p_res.set_parameter(k.to_sym, v)
        end
        @scope.compiler.add_resource(@scope, p_res)
        previous = p_res.to_s
        Puppet::debug("*** Resource '#{previous}' created succefful.")
      end
    end
  end
end

module Puppet::Parser::Functions
  newfunction(:create_predefined_networks_and_routers , :doc => <<-EOS
    This function get Hash of neutron configuration
    and create predefined networks and routers.

    Example call:
    $config = create_predefined_networks_and_routers($neutron_settings_hash)

    EOS
  ) do |argv|
    #Puppet::Parser::Functions.autoloader.loadall
    nr_conf = MrntNeutronNR.new(self, MrntNeutronNR.sanitize_hash(argv[0]))
    nr_conf.create_resources()
  end
end
# vim: set ts=2 sw=2 et :
