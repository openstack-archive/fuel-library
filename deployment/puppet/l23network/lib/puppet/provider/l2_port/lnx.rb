require File.join(File.dirname(__FILE__), '..','..','..','puppet/provider/lnx_base')

Puppet::Type.type(:l2_port).provide(:lnx, :parent => Puppet::Provider::Lnx_base) do
  defaultfor :osfamily    => :linux
  commands   :iproute     => 'ip',
             :ethtool_cmd => 'ethtool',
             :brctl       => 'brctl',
             :vsctl       => 'ovs-vsctl'


  def self.instances
    rv = []
    #todo: what do with OVS ports, inserted in LNX bridge? i.e. port located in two bridges.
    ports = get_lnx_ports()
    ovs_interfaces = get_ovs_interfaces()
    ports.each_pair do |if_name, if_props|
      props = {
        :ensure          => :present,
        :name            => if_name,
        :vendor_specific => {}
      }
      debug("prefetching interface '#{if_name}'")
      props.merge! if_props
      props[:ethtool] = get_iface_ethtool_hash(if_name, nil)
      # add PROVIDER prefix to port type flags and convert port_type to string
      if ovs_interfaces.has_key? if_name and ovs_interfaces[if_name][:port_type].is_a? Array and ovs_interfaces[if_name][:port_type].include? 'internal'
        if_provider = ovs_interfaces[if_name][:provider]
        props[:port_type] = ovs_interfaces[if_name][:port_type]
        props[:provider] = ovs_interfaces[if_name][:provider]
      else
        if_provider = props[:provider]
      end
      props[:port_type] = props[:port_type].insert(0, if_provider).join(':')
      if if_provider == 'lnx'
        rv << new(props)
        debug("PREFETCH properties for '#{if_name}': #{props}")
      else
        debug("SKIP properties for '#{if_name}': #{props}")
      end
    end
    return rv
  end

  def exists?
    @property_hash[:ensure] == :present
  end

  def create
    debug("CREATE resource: #{@resource}")
    @old_property_hash = {}
    @property_flush = {}.merge! @resource
    # todo: divide simple creating interface and vlan
    iproute('link', 'add', 'link', @resource[:vlan_dev], 'name', @resource[:interface], 'type', 'vlan', 'id', @resource[:vlan_id])
  end

  def destroy
    debug("DESTROY resource: #{@resource}")
    # todo: Destroing of L2 resource -- is a putting interface to the DOWN state.
    #       Or remove, if ove a vlan interface
    #iproute('--force', 'addr', 'flush', 'dev', @resource[:interface])
  end

  def initialize(value={})
    super(value)
    @property_flush = {}
    @old_property_hash = {}
    @old_property_hash.merge! @property_hash
  end

  def flush
    if @property_flush
      debug("FLUSH properties: #{@property_flush}")
      #
      # FLUSH changed properties
      if ! @property_flush[:mtu].nil?
        File.open("/sys/class/net/#{@resource[:interface]}/mtu", "w") { |f| f.write(@property_flush[:mtu]) }
      end
      if @property_flush.has_key? :bond_master
        bond = @old_property_hash[:bond_master]
        # putting interface to the down-state, because add/remove upped interface impossible. undocumented kern.behavior.
        iproute('--force', 'link', 'set', 'dev', @resource[:interface], 'down')
        if bond and bond != :absent
          # remove interface from bond, if one included to it
          debug("Remove interface '#{@resource[:interface]}' from bond '#{bond}'.")
          File.open("/sys/class/net/#{@resource[:interface]}/master/bonding/slaves", "a") {|f| f << "-#{@resource[:interface]}"}
        end
        if ! @property_flush[:bond_master].nil? and @property_flush[:bond_master] != :absent
          # add interface as slave to bond
          debug("Add interface '#{@resource[:interface]}' to bond '#{@property_flush[:bond_master]}'.")
          File.open("/sys/class/net/#{@property_flush[:bond_master]}/bonding/slaves", "a") {|f| f << "+#{@resource[:interface]}"}
        else
          # port no more member of any bonds
          @property_flush[:port_type] = nil
        end
      end
      if @property_flush.has_key? :bridge
        # get actual bridge-list. We should do it here,
        # because bridge may be not existing at prefetch stage.
        @bridges ||= self.class.get_bridge_list  # resource port can't change bridge list
        debug("Actual-bridge-list: #{@bridges}")
        port_bridges_hash = self.class.get_port_bridges_pairs()
        debug("Actual-port-bridge-mapping: '#{port_bridges_hash}'")       # it should removed from LNX
        #
        iproute('--force', 'link', 'set', 'dev', @resource[:interface], 'down')
        # remove interface from old bridge
        if ! port_bridges_hash[@resource[:interface]].nil?
          br_name = port_bridges_hash[@resource[:interface]][:bridge]
          br_type = port_bridges_hash[@resource[:interface]][:br_type]
          if br_name != @resource[:interface]
            # do not remove bridge-based interface from his bridge
            case br_type
            when :ovs
              vsctl('del-port', br_name, @resource[:interface])
            when :lnx
              brctl('delif', br_name, @resource[:interface])
            else
              #pass
            end
          end
        end
        # add port to the new bridge
        if !@property_flush[:bridge].nil? and @property_flush[:bridge].to_sym != :absent
          case @bridges[@property_flush[:bridge]][:br_type]
          when :ovs
            vsctl('add-port', @property_flush[:bridge], @resource[:interface])
          when :lnx
            brctl('addif', @property_flush[:bridge], @resource[:interface])
          else
            #pass
          end
        end
        iproute('link', 'set', 'dev', @resource[:interface], 'up') if @resource[:onboot]
        debug("Change bridge")
      end
      if @property_flush.has_key? :ethtool and @property_flush[:ethtool].is_a? Hash
        @property_flush[:ethtool].each_pair do |section, pairs|
          debug("Setup '#{section}' by ethtool for interface '#{@resource[:interface]}'.")
          optmaps = self.class.get_ethtool_name_commands_mapping[section]
          if optmaps
            pairs.each_pair do |k,v|
              if optmaps.has_key? k
                ethtool_cmd(optmaps['__section_key_set__'], @resource[:interface], optmaps[k], v ? 'on':'off')
              end
            end
          else
            warn("No mapping for ethtool section '#{section}' for interface '#{@resource[:interface]}'.")
          end
        end
      end
      if ! @property_flush[:onboot].nil?
        # Should be after bond, because interface may auto-upped while added to the bond
        debug("Setup UP state for interface '#{@resource[:interface]}'.")
        iproute('link', 'set', 'dev', @resource[:interface], 'up')
      end
      @property_hash = resource.to_hash
    end
  end

  #-----------------------------------------------------------------
  def bridge
    @property_hash[:bridge] || :absent
  end
  def bridge=(val)
    @property_flush[:bridge] = val
  end

  def vlan_dev
    @property_hash[:vlan_dev] || :absent
  end
  def vlan_dev=(val)
    @property_flush[:vlan_dev] = val
  end

  def vlan_id
    @property_hash[:vlan_id] || :absent
  end
  def vlan_id=(val)
    @property_flush[:vlan_id] = val
  end

  def port_type
    @property_hash[:port_type] || :absent
  end
  def port_type=(val)
    @property_flush[:port_type] = val
  end

  def vlan_mode
    @property_hash[:vlan_mode] || :absent
  end
  def vlan_mode=(val)
    @property_flush[:vlan_mode] = val
  end

  def bond_master
    @property_hash[:bond_master] || :absent
  end
  def bond_master=(val)
    @property_flush[:bond_master] = val
  end

  def mtu
    @property_hash[:mtu] || :absent
  end
  def mtu=(val)
    @property_flush[:mtu] = val if val
  end

  def onboot
    @property_hash[:onboot] || :absent
  end
  def onboot=(val)
    @property_flush[:onboot] = val
  end

  def ethtool
    @property_hash[:ethtool] || nil
  end
  def ethtool=(val)
    @property_flush[:ethtool] = val
  end

  def vendor_specific
    @property_hash[:vendor_specific] || nil
  end
  def vendor_specific=(val)
    @property_flush[:vendor_specific] = val
  end

  def type
    :absent
  end
  def type=(value)
    debug("Resource '#{@resource[:name]}': Doesn't support interface type change.")
  end

end
# vim: set ts=2 sw=2 et :