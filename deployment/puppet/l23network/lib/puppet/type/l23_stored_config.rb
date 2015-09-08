# type for managing persistent interface config options
# Inspired by puppet-network module. Adrien, thanks.

require 'ipaddr'

Puppet::Type.newtype(:l23_stored_config) do
  @doc = "Manage lines in interface config file"
  desc @doc

  feature :provider_options, <<-EOD
    The provider can accept a hash of arbitrary options. The semantics of
    these options will depend on the provider.
  EOD

  ensurable

  newparam(:name) do
    isnamevar
    desc "The name of the physical or logical network device"
  end

  newproperty(:method) do
    desc "The method for determining an IP address for the interface"
    # static -- assign IP address in config
    # manual -- UP interface without IP address
    newvalues(:static, :absent, :manual, :dhcp, :loopback, :none, :undef, :nil)
    aliasvalue(:none,  :manual)
    aliasvalue(:undef, :absent)
    aliasvalue(:nil,   :absent)
    defaultto :manual
  end

  # newproperty(:port_type) do
  #   desc "port_type fake RO property"
  # end

  newproperty(:if_type) do
    desc "Device type. Service property, shouldn't be setting by puppet"
    newvalues(:ethernet, :bridge, :bond)
  end

  newproperty(:if_provider) do
    desc "Device provider. Service property, shouldn't be setting by puppet"
  end

  newproperty(:bridge, :array_matching => :all) do
    # Array_matching for this property required for very complicated cases
    # ex. patchcord for connectind two bridges or bridge and network namesspace
    desc "Name of bridge, including this port"
    newvalues(/^[\w+\-]+$/, :none, :undef, :nil, :absent)
    aliasvalue(:none,  :absent)
    aliasvalue(:undef, :absent)
    aliasvalue(:nil,   :absent)
    defaultto :absent
  end

  newproperty(:jacks, :array_matching => :all) do
    desc "Name of jacks for patchcord"
    newvalues(/^[\w+\-]+$/)
  end

  newproperty(:bridge_ports, :array_matching => :all) do
    desc "Ports, member of bridge, service property, do not use directly."
  end

  newproperty(:bridge_stp) do
    desc "Whether stp enable"
    newvalues(:true, :absent, :yes, :on, :false, :no, :off)
    aliasvalue(:yes, :true)
    aliasvalue(:on,  :true)
    aliasvalue(:no,  :false)
    aliasvalue(:off, :false)
    defaultto :absent
  end

  newproperty(:onboot) do
    desc "Whether to bring the interface up on boot"
    newvalues(:true, :yes, :on, :false, :no, :off)
    aliasvalue(:yes, :true)
    aliasvalue(:on,  :true)
    aliasvalue(:no,  :false)
    aliasvalue(:off, :false)
    defaultto :true

    def insync?(value)
      value.to_s.downcase == should.to_s.downcase
    end
  end

  newproperty(:mtu) do
    desc "The Maximum Transmission Unit size to use for the interface"
    newvalues(/^\d+$/, :absent, :none, :undef, :nil)
    aliasvalue(:none,  :absent)
    aliasvalue(:undef, :absent)
    aliasvalue(:nil,   :absent)
    aliasvalue(0,      :absent)
    defaultto :absent   # MTU value should be undefined by default, because some network resources (bridges, subinterfaces)
    validate do |value| #     inherits it from a parent interface
      # Intel 82598 & 82599 chips support MTUs up to 16110; is there any
      # hardware in the wild that supports larger frames?
      #
      # It appears loopback devices routinely have large MTU values; Eg. 65536
      #
      # Frames small than 64bytes are discarded as runts.  Smallest valid MTU
      # is 42 with a 802.1q header and 46 without.
      min_mtu = 42
      max_mtu = 65536
      if ! (value.to_s == 'absent' or (min_mtu .. max_mtu).include?(value.to_i))
        raise ArgumentError, "'#{value}' is not a valid mtu (must be a positive integer in range (#{min_mtu} .. #{max_mtu})"
      end
    end
    munge do |val|
      ((val == :absent)  ?  :absent  :  val.to_i)
    end
  end

  newproperty(:vlan_dev) do
    desc "802.1q vlan base device"
  end

  newproperty(:vlan_id) do
    desc "802.1q vlan ID"
    newvalues(/^\d+$/, :absent, :none, :undef, :nil)
    aliasvalue(:none,  :absent)
    aliasvalue(:undef, :absent)
    aliasvalue(:nil,   :absent)
    aliasvalue(0,      :absent)
    defaultto :absent
    validate do |val|
      min_vid = 1
      max_vid = 4094
      if ! (val.to_s == 'absent' or (min_vid .. max_vid).include?(val.to_i))
        raise ArgumentError, "'#{val}' is not a valid 802.1q NALN_ID (must be a integer value in range (#{min_vid} .. #{max_vid})"
      end
    end
    munge do |val|
      ((val == :absent)  ?  :absent  :  val.to_i)
    end
  end

  newproperty(:vlan_mode) do
    desc "802.1q vlan interface naming model"
    #newvalues(:ethernet, :bridge, :bond)
    #defaultto :ethernet
  end


  newproperty(:ipaddr) do
    desc "Primary IP address for interface"
    newvalues(/^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\/\d{1,2}$/, :absent, :none, :undef, :nil, :dhcp)
    aliasvalue(:none,  :absent)
    aliasvalue(:undef, :absent)
    aliasvalue(:nil,   :absent)
    defaultto :absent
  end

  newproperty(:gateway) do
    desc "Default gateway"
    newvalues(/^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$/, :absent, :none, :undef, :nil)
    aliasvalue(:none,  :absent)
    aliasvalue(:undef, :absent)
    aliasvalue(:nil,   :absent)
    defaultto :absent
  end

  newproperty(:gateway_metric) do
    desc "Default gateway metric"
    newvalues(/^\d+$/, :absent, :none, :undef, :nil)
    aliasvalue(:none,  :absent)
    aliasvalue(:undef, :absent)
    aliasvalue(:nil,   :absent)
    aliasvalue(0,      :absent)
    defaultto :absent
    validate do |val|
      min_metric = 0
      max_metric = 65535
      if ! (val.to_s == 'absent' or (min_metric .. max_metric).include?(val.to_i))
        raise ArgumentError, "'#{val}' is not a valid metric (must be a integer value in range (#{min_metric} .. #{max_metric})"
      end
    end
    munge do |val|
      ((val == :absent)  ?  :absent  :  val.to_i)
    end
  end

  newproperty(:delay_while_up) do
    desc "Delay while interface stay UP"
    newvalues(/^\d+$/, :absent, :none, :undef, :nil)
    aliasvalue(:none,  :absent)
    aliasvalue(:undef, :absent)
    aliasvalue(:nil,   :absent)
    aliasvalue(0,      :absent)
    defaultto :absent
    munge do |val|
      ((val == :absent)  ?  :absent  :  [val.to_i])
    end
  end

  newproperty(:bond_master) do
    desc "bond name for bonded interface"
    newvalues(/^\w[\w+\-]*\w$/, :none, :undef, :nil, :absent)
    aliasvalue(:none,  :absent)
    aliasvalue(:undef, :absent)
    aliasvalue(:nil,   :absent)
    defaultto :absent
  end

  newproperty(:bond_slaves, :array_matching => :all) do
    desc "slave ports for bond interface"
    newvalues(/^\w[\w+\-\.]*\w$/, :false, :none, :undef, :nil, :absent)
    #aliasvalue(:absent, :none)  # none is a valid config value
    aliasvalue(:false, :none)
    aliasvalue(:undef, :absent)
    aliasvalue(:nil,   :absent)
    defaultto :absent
  end

  newproperty(:bond_mode)
  newproperty(:bond_miimon)
  newproperty(:bond_lacp)
  newproperty(:bond_lacp_rate)
  newproperty(:bond_xmit_hash_policy)

  newproperty(:bond_updelay) do
    newvalues(/^\d+$/)
  end

  newproperty(:bond_downdelay) do
    newvalues(/^\d+$/)
  end

  newproperty(:bond_ad_select) do
    validate do |val|
      allowed_values = ['0','1','2','stable','bandwidth','count']
      if ! allowed_values.include? val.to_s
        raise ArgumentError, "'#{val}' is not a valid bond_ad_select. Only #{allowed_values.join(', ')} allowed.)"
      end
    end
  end

  # # `:options` provides an arbitrary passthrough for provider properties, so
  # # that provider specific behavior doesn't clutter up the main type but still
  # # allows for more powerful actions to be taken.
  # newproperty(:options, :required_features => :provider_options) do
  #   desc "Provider specific options to be passed to the provider"

  #   def is_to_s(hash = @is)
  #     hash.keys.sort.map {|key| "#{key} => #{hash[key]}"}.join(", ")
  #   end

  #   def should_to_s(hash = @should)
  #     hash.keys.sort.map {|key| "#{key} => #{hash[key]}"}.join(", ")
  #   end

  #   defaultto {}

  #   validate do |value|
  #     raise ArgumentError, "#{self.class} requires a hash for the options property" unless value.is_a? Hash
  #     #provider.validate
  #   end
  # end

  newproperty(:routes) do
    desc "routes, corresponded to this interface. This-a R/O property, that autofill from L3_route resource"
    #defaultto {}  # no default value should be!!!
    validate do |val|
      if ! val.is_a? Hash
        fail("routes should be a hash!")
      end
    end

    munge do |value|
      (value.empty?  ?  nil  :  L23network.reccursive_sanitize_hash(value))
    end

    def should_to_s(value)
      "\n#{value.to_yaml.gsub('!ruby/sym','')}\n"
    end

    def is_to_s(value)
      "\n#{value.to_yaml.gsub('!ruby/sym','')}\n"
    end
  end

  newproperty(:ethtool) do
    desc "ethtool addition configuration for this interface"
    #defaultto {}  # no default value should be!!!
    validate do |val|
      if ! val.is_a? Hash
        fail("ethtool commands should be a hash!")
      end
    end

    munge do |value|
      (value.empty?  ?  nil  :  L23network.reccursive_sanitize_hash(value))
    end

    def should_to_s(value)
      "\n#{value.to_yaml.gsub('!ruby/sym','')}\n"
    end

    def is_to_s(value)
      "\n#{value.to_yaml.gsub('!ruby/sym','')}\n"
    end
  end

  newproperty(:vendor_specific) do
    desc "Hash of vendor specific properties"
    #defaultto {}  # no default value should be!!!
    # provider-specific properties, can be validating only by provider.
    validate do |val|
      if ! val.is_a? Hash
        fail("Vendor_specific should be a hash!")
      end
    end

    munge do |value|
      (value.empty?  ?  nil  :  L23network.reccursive_sanitize_hash(value))
    end

    def should_to_s(value)
      "\n#{value.to_yaml.gsub('!ruby/sym ','')}\n"
    end

    def is_to_s(value)
      "\n#{value.to_yaml.gsub('!ruby/sym ','')}\n"
    end

    def insync?(value)
      should_to_s(value) == should_to_s(should)
    end
  end


  def generate
    # if_type = :ethernet is the same as if_type = nil
    if (!([:absent, :none, :nil, :undef] & self[:bridge]).any? and ([:ethernet, :bond].include? self[:if_type] or self[:if_type].nil?))
      self[:bridge].each do |bridge|
        br = self.catalog.resource('L23_stored_config', bridge)
        fail("Stored_config resource for bridge '#{bridge}' not found for port '#{self[:name]}'!") if ! br
        br[:bridge_ports] ||= []
        ports = br[:bridge_ports]
        return if ! ports.is_a? Array
        if ! ports.include? self[:name]
          ports << self[:name].to_s
          br[:bridge_ports] = ports.reject{|a| a=='none'}.sort
        end
      end
    end
    # find routes, that should be applied while this interface UP
    if !['', 'none', 'absent'].include?(self[:ipaddr].to_s.downcase)
      l3_routes = self.catalog.resources.reject{|nnn| nnn.ref.split('[')[0]!='L3_route'}
      my_network = IPAddr.new(self[:ipaddr].to_s.downcase) # only primary IP ADDR use !!!
      my_route = {}
      l3_routes.each do |rou|
        if my_network.include? rou[:gateway]
          #self[:routes] = {} if self[:routes].nil?
          my_route[rou[:name]] = {
            :gateway     => rou[:gateway],
            :destination => rou[:destination]
          }
          my_route[rou[:name]][:metric] = rou[:metric] if !['', 'absent'].include? rou[:metric].to_s.downcase
          debug("+++My route: #{my_route}")
        end
      end
      if ! my_route.empty?
        if self[:routes].nil?
          self[:routes] = my_route
        else
          self[:routes].merge!(my_route)
        end
      end
    end
    nil
  end
end
# vim: set ts=2 sw=2 et :
