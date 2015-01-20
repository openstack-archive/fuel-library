require File.join(File.dirname(__FILE__), '..','..','..','puppet/provider/lnx_base')

Puppet::Type.type(:l2_bond).provide(:lnx, :parent => Puppet::Provider::Lnx_base) do
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
    bonds ||= self.get_lnx_bonds()
    debug("bonds found: #{bonds.keys}")
    rv = []
    bonds.each_pair do |bond_name, bond_props|
        props = {
          :ensure     => :present,
          :name       => bond_name,
        }
        props.merge! bond_props
        # # get bridge if port included to it
        # if ! port_bridges_hash[if_name].nil?
        #   props[:bridge] = port_bridges_hash[if_name][:bridge]
        # end
        # # calculate port_type field
        # if !bridges[if_name].nil?
        #   case bridges[if_name][:br_type]
        #   when :ovs
        #     props[:port_type] = 'ovs:br:unremovable'
        #   when :lnx
        #     props[:port_type] = 'lnx:br:unremovable'
        #   else
        #     # pass
        #   end
        # end
        debug("PREFETCHED properties for '#{bond_name}': #{props}")
        rv << new(props)
    end
    rv
  end

  def exists?
    @property_hash[:ensure] == :present
  end

  def create
    debug("CREATE resource: #{@resource}")
    @old_property_hash = {}
    @property_flush = {}.merge! @resource
    open('/sys/class/net/bonding_masters', 'a') do |f|
      f << "+#{@resource[:name]}"
    end
  end

  def destroy
    debug("DESTROY resource: #{@resource}")
    open('/sys/class/net/bonding_masters', 'a') do |f|
      f << "-#{@resource[:name]}"
    end
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
      if @property_flush.has_key? :slaves
        runtime_slave_ports = File.open("/sys/class/net/#{@resource[:bond]}/bonding/slaves", "r").read.split(/\s+/)
        if @property_flush[:slaves].nil? or @property_flush[:slaves] == :absent
          debug("Remove all slave ports from bond '#{@resource[:bond]}'")
          rm_slave_list = runtime_slave_ports
        else
          rm_slave_list = runtime_slave_ports - @property_flush[:slaves]
          debug("Remove '#{rm_slave_list.join(',')}' ports from bond '#{@resource[:bond]}'")
          rm_slave_list.each do |slave|
            iproute('link', 'set', 'dev', slave, 'down')  # need by kernel requirements by design. undocumented :(
            File.open("/sys/class/net/#{@resource[:bond]}/bonding/slaves", "a") {|f| f << "-#{slave}"}
          end
        end
        # We shouldn't add ports here, because bond configures early, than ports.
        # corresponded ports may be unconfigured at this time.
        # corresponded ports will be add himself to bond while configuration
      end
      if @property_flush.has_key? :bond_properties
        # change bond_properties
        need_reassemble = [:mode, :lacp_rate]
        #todo(sv): inplement re-assembling only if it need
        #todo(sv): re-set only delta between reality and requested
        runtime_bond_state  = !self.class.get_iface_state(@resource[:bond]).nil?
        runtime_slave_ports = File.open("/sys/class/net/#{@resource[:bond]}/bonding/slaves", "r").read.split(/\s+/)
        runtime_slave_ports.each do |eth|
          # for most bond options we should disassemble bond before re-configuration. In the kernel module documentation
          # says, that bond interface should be downed, but it's not enouth.
          File.open("/sys/class/net/#{@resource[:bond]}/bonding/slaves", "a") {|f| f << "-#{eth}"}
        end
        iproute('link', 'set', 'dev', @resource[:bond], 'down')
        @property_flush[:bond_properties].each_pair do |prop, val|
          if self.class.lnx_bond_allowed_properties_list.include? prop.to_sym
            act_val = val.to_s
          else
            debug("Unsupported property '#{prop}' for bond '#{@resource[:bond]}'")
            act_val = nil
          end
          if act_val
            debug("Set property '#{prop}' to '#{act_val}' for bond '#{@resource[:bond]}'")
            File.open("/sys/class/net/#{@resource[:bond]}/bonding/#{prop}", 'a') {|f| f << "#{act_val.to_s}"}
          end
        end
        # re-assemble bond after configuration
        iproute('link', 'set', 'dev', @resource[:bond], 'up') if runtime_bond_state
        runtime_slave_ports.each do |eth|
          File.open("/sys/class/net/#{@resource[:bond]}/bonding/slaves", "a") {|f| f << "+#{eth}"}
        end
      end
      if @property_flush.has_key? :bridge
        # get actual bridge-list. We should do it here,
        # because bridge may be not existing at prefetch stage.
        @bridges ||= self.class.get_bridge_list()
        debug("Actual-bridge-list: #{@bridges}")
        port_bridges_hash = self.class.get_port_bridges_pairs()
        debug("Actual-port-bridge-mapping: '#{port_bridges_hash}'")       # it should removed from LNX
        #
        # remove interface from old bridge
        runtime_bond_state  = !self.class.get_iface_state(@resource[:bond]).nil?
        iproute('--force', 'link', 'set', 'dev', @resource[:bond], 'down')
        if ! port_bridges_hash[@resource[:bond]].nil?
          br_name = port_bridges_hash[@resource[:bond]][:bridge]
          if br_name != @resource[:bond]
            # do not remove bridge-based interface from his bridge
            case port_bridges_hash[@resource[:bond]][:br_type]
            when :ovs
              vsctl('del-port', br_name, @resource[:bond])
              # todo catch exception
            when :lnx
              brctl('delif', br_name, @resource[:bond])
              # todo catch exception
            else
              #pass
            end
          end
        end
        # add port to the new bridge
        if !@property_flush[:bridge].nil? and @property_flush[:bridge].to_sym != :absent
          case @bridges[@property_flush[:bridge]][:br_type]
          when :ovs
            vsctl('add-port', @property_flush[:bridge], @resource[:bond])
          when :lnx
            brctl('addif', @property_flush[:bridge], @resource[:bond])
          else
            #pass
          end
        end
        iproute('link', 'set', 'dev', @resource[:bond], 'up') if runtime_bond_state
        debug("Change bridge")
      end
      if ! @property_flush[:mtu].nil?
        File.open("/sys/class/net/#{@resource[:bond]}/mtu", "w") { |f| f.write(@property_flush[:mtu]) }
      end
      if ! @property_flush[:onboot].nil?
        iproute('link', 'set', 'dev', @resource[:bond], 'up')
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

  def port_type
    @property_hash[:port_type] || :absent
  end
  def port_type=(val)
    @property_flush[:port_type] = val
  end

  def slaves
    @property_hash[:slaves] || :absent
  end
  def slaves=(val)
    @property_flush[:slaves] = val
  end

  def bond_properties
    @property_hash[:bond_properties] || :absent
  end
  def bond_properties=(val)
    @property_flush[:bond_properties] = val
  end

  def interface_properties
    @property_hash[:interface_properties] || :absent
  end
  def interface_properties=(val)
    @property_flush[:interface_properties] = val
  end

  def mtu
    @property_hash[:mtu] || :absent
  end
  def mtu=(val)
    @property_flush[:mtu] = val
  end

  def onboot
    @property_hash[:onboot] || :absent
  end
  def onboot=(val)
    @property_flush[:onboot] = val
  end

end
# vim: set ts=2 sw=2 et :