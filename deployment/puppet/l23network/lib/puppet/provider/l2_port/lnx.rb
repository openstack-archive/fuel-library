require File.join(File.dirname(__FILE__), '..','..','..','puppet/provider/lnx_base')

Puppet::Type.type(:l2_port).provide(:lnx, :parent => Puppet::Provider::Lnx_base) do
  defaultfor :osfamily => :linux
  commands   :iproute => 'ip',
             :brctl   => 'brctl',
             :vsctl   => 'ovs-vsctl'


  def self.prefetch(resources)
    interfaces = instances
    resources.keys.each do |name|
      if provider = interfaces.find{ |ii| ii.name == name }
        resources[name].provider = provider
      end
    end
  end

  def self.instances
    bridges ||= get_bridge_list()
    #todo: what do with OVS ports, inserted in LNX bridge? i.e. port located in two bridges.
    port_bridges_hash = self.get_lnx_port_bridges_pairs()
    #debug("port-bridges: '#{port_bridges_hash}'")
    port_bridges_hash.merge! self.get_ovs_port_bridges_pairs()
    debug("port-bridges mapping: '#{port_bridges_hash}'")
    # parse 802.1q vlan interfaces
    vlan_ifaces = {}
    rc_c = /([\w+\.\-]+)\s*\|\s*(\d+)\s*\|\s*([\w+\-]+)/
    File.open("/proc/net/vlan/config", "r").each do |line|
      if (rv=line.match(rc_c))
        vlan_ifaces[rv[1]] = {
          :vlan_dev  => rv[3],
          :vlan_id   => rv[2],
          :vlan_mode => (rv[1].match('\.').nil?  ?  'vlan'  :  'eth'  )
        }
      end
    end
    # parse all system interfaces
    re_c = /^\s*([0-9A-Za-z\.\-\_]+):/
    File.open("/proc/net/dev", "r").each.select{|line| line.match(re_c)}.collect do |if_line|
        mm = if_line.match(re_c)
        if_name = mm[1]
        props = {
          :ensure          => :present,
          :name            => if_name,
          :port_type       => '',
          :vendor_specific => {}
        }
        debug("prefetching interface '#{if_name}'")
        # check, whether this interface is vlan
        if File.file?("/proc/net/vlan/#{if_name}")
          props.merge!(vlan_ifaces[if_name])
        else
          props.merge!({
            :vlan_dev  => nil,
            :vlan_id   => nil,
            :vlan_mode => nil
          })
        end
        # check whether interface UP
        begin
          File.open("/sys/class/net/#{if_name}/carrier", "r").each.select{|l| l.match(/^(\d+)$/)}.size
          props[:onboot] = true
        rescue
          # if interface if down, this file can't be read
          props[:onboot] = false
        end

        # get MTU
        if File.open("/sys/class/net/#{if_name}/mtu", "r").each.select{|l| l.match(/^(\d+)$/)}.size > 0
          props[:mtu] = $1.to_s
        end
        # get bridge if port included to it
        if ! port_bridges_hash[if_name].nil?
          props[:bridge] = port_bridges_hash[if_name][:bridge]
        end
        # calculate port_type field
        if File.directory?("/sys/class/net/#{if_name}/bonding")
          # port is a bond
          props[:port_type] = 'lnx:bond:unremovable'
        elsif File.symlink?("/sys/class/net/#{if_name}/master")
          # port is a slave of bond
          props[:bond_master] = File.readlink("/sys/class/net/#{if_name}/master").split('/')[-1]
          props[:port_type] = 'lnx:bond-slave'
        end
        if !bridges[if_name].nil?
          case bridges[if_name][:br_type]
          when :ovs
            props[:port_type] = 'ovs:br:unremovable'
          when :lnx
            props[:port_type] = 'lnx:br:unremovable'
          else
            # pass
          end
        end
        debug("PREFETCHED properties for '#{if_name}': #{props}")
        new(props)
    end
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
        if bond
          # remove interface from bond, if one included to it
          debug("Remove interface '#{@resource[:interface]}' from bond '#{bond}'.")
          File.open("/sys/class/net/#{@resource[:interface]}/master/bonding/slaves", "a") {|f| f << "-#{@resource[:interface]}"}
        end
        if ! @property_flush[:bond_master].nil?
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

  def vendor_specific
    @property_hash[:vendor_specific] || {}
  end
  def vendor_specific=(val)
    @property_flush[:vendor_specific] = val
  end

end
# vim: set ts=2 sw=2 et :