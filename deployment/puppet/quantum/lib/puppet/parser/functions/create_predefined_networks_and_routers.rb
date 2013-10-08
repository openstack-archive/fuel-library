# require 'ipaddr'
# require 'yaml'
# require 'json'

class MrntQuantumNR
  def initialize(scope, cfg)
    @scope = scope
    @quantum_config = cfg
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

  def get_default_router_config()
    Marshal.load(Marshal.dump({
      :name    => nil,
      :tenant  => 'admin',
      :int_subnets => nil,
      :ext_net     => nil,
    }))
  end

  def get_default_network_config()
    Marshal.load(Marshal.dump({
      :net => {
        :name         => nil,
        :tenant       => 'admin',
        :network_type => nil,
        :physnet      => nil,
        :router_ext   => nil,
        :shared       => nil,
        :segment_id   => nil,
      },
      :subnet => {
        :name    => nil,
        :tenant  => 'admin',
        :network => nil,  # Network id or name this subnet belongs to
        :cidr    => nil,  # CIDR of subnet to create
        :gateway => nil,
        :alloc_pool  => nil,  # Allocation pool IP addresses
        :nameservers => nil,  # DNS name servers used by hosts
      },
    }))
  end

  def create_resources()
    res__quantum_net = 'quantum_net'
    res__quantum_net_type = Puppet::Type.type(res__quantum_net.downcase.to_sym)
    res__quantum_subnet = 'quantum_subnet'
    res__quantum_subnet_type = Puppet::Type.type(res__quantum_subnet.downcase.to_sym)
    res__quantum_router = 'quantum_router'
    res__quantum_router_type = Puppet::Type.type(res__quantum_router.downcase.to_sym)
    previous = nil
    @quantum_config[:predefined_networks].each do |net, ncfg|
      # config network resources parameters
      network_config = get_default_network_config()
      network_config[:net][:name] = net.to_s
      network_config[:net][:network_type] = ncfg[:L2][:network_type]
      network_config[:net][:physnet] = ncfg[:L2][:physnet]
      network_config[:net][:router_ext] = ncfg[:L2][:router_ext]
      network_config[:net][:shared] = ncfg[:shared]
      network_config[:net][:segment_id] = ncfg[:L2][:segment_id]
      network_config[:subnet][:name] = "#{net.to_s}__subnet"
      network_config[:subnet][:network] = network_config[:net][:name]
      network_config[:subnet][:cidr] = ncfg[:L3][:subnet]
      network_config[:subnet][:gateway] = ncfg[:L3][:gateway]
      network_config[:subnet][:nameservers] = ncfg[:L3][:nameservers]
      if ncfg[:L3][:floating]
        floating_a = ncfg[:L3][:floating].split(/[\:\-]/)
        if floating_a.size != 2
          raise(Puppet::ParseError, "You must define floating range for network '#{net}' as pair of IP addresses, not a #{ncfg[:L3][:floating]}")
        end
        network_config[:subnet][:alloc_pool] = "start=#{floating_a[0]},end=#{floating_a[1]}"
      end
      # create quantum_net resource
      p_res = Puppet::Parser::Resource.new(
        res__quantum_net,
        network_config[:net][:name],
        :scope => @scope,
        :source => res__quantum_net_type
      )
      previous && p_res.set_parameter(:require, [previous])
      network_config[:net].each do |k,v|
        v && p_res.set_parameter(k,v)
      end
      @scope.compiler.add_resource(@scope, p_res)
      previous = p_res.to_s
      Puppet::debug("*** Resource '#{previous}' created succefful.")
      # create quantum_subnet resource
      p_res = Puppet::Parser::Resource.new(
        res__quantum_subnet,
        network_config[:subnet][:name],
        :scope => @scope,
        :source => res__quantum_subnet_type
      )
      p_res.set_parameter(:require, [previous])
      network_config[:subnet].each do |k,v|
        v && p_res.set_parameter(k,v)
      end
      @scope.compiler.add_resource(@scope, p_res)
      previous = p_res.to_s
      Puppet::debug("*** Resource '#{previous}' created succefful.")
    end
    # create pre-defined routers
    if previous # if no networks -- we don't create any router
      @quantum_config[:predefined_routers].each do |rou, rcfg|
        next if rcfg[:virtual]
        # config router
        router_config = get_default_router_config()
        router_config[:name] = rou.to_s
        rcfg[:tenant] && router_config[:tenant] = rcfg[:tenant]
        router_config[:ext_net] = rcfg[:external_network]
        router_config[:int_subnets] = rcfg[:internal_networks]
        # create resource
        p_res = Puppet::Parser::Resource.new(
          res__quantum_router,
          router_config[:name],
          :scope => @scope,
          :source => res__quantum_router_type
        )
        p_res.set_parameter(:require, [previous])
        router_config.each do |k,v|
          v && p_res.set_parameter(k,v)
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
    This function get Hash of Quantum configuration
    and create predefined networks and routers.

    Example call:
    $config = create_predefined_networks_and_routers($quantum_settings_hash)

    EOS
  ) do |argv|
    #Puppet::Parser::Functions.autoloader.loadall
    nr_conf = MrntQuantumNR.new(self, MrntQuantumNR.sanitize_hash(argv[0]))
    nr_conf.create_resources()
  end
end
# vim: set ts=2 sw=2 et :