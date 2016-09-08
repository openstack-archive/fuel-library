# Native linux bonding implementation
# INspired by: https://www.kernel.org/doc/Documentation/networking/bonding.txt
#

require_relative '../lnx_base'

Puppet::Type.type(:l2_bond).provide(:lnx, :parent => Puppet::Provider::Lnx_base) do
  defaultfor :kernel    => :linux
  commands   :ethtool_cmd => 'ethtool'


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
          :ensure          => :present,
          :name            => bond_name,
          :vendor_specific => {}
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

  def create
    debug("CREATE resource: #{@resource}")
    @old_property_hash = {}
    @property_flush = {}.merge! @resource
    self.class.set_sys_class('/sys/class/net/bonding_masters', "+#{@resource[:name]}")
  end

  def destroy
    debug("DESTROY resource: #{@resource}")
    self.class.set_sys_class('/sys/class/net/bonding_masters', "-#{@resource[:name]}")
  end

  def flush
    if ! @property_flush.empty?
      debug("FLUSH properties: #{@property_flush}")
      bond_prop_dir = "/sys/class/net/#{@resource[:bond]}"
      # FLUSH changed properties
      if @property_flush.has_key? :slaves
        runtime_slave_ports = self.class.get_sys_class("/sys/class/net/#{@resource[:bond]}/bonding/slaves", true)
        if @property_flush[:slaves].nil? or @property_flush[:slaves] == :absent
          debug("Remove all slave ports from bond '#{@resource[:bond]}'")
          rm_slave_list = runtime_slave_ports
        else
          rm_slave_list = runtime_slave_ports - @property_flush[:slaves]
          if !rm_slave_list.empty?
            debug("Remove '#{rm_slave_list.join(',')}' ports from bond '#{@resource[:bond]}'")
            rm_slave_list.each do |slave|
              self.class.interface_down(slave)  # need by kernel requirements by design. undocumented :(
              self.class.set_sys_class("#{bond_prop_dir}/bonding/slaves", "-#{slave}")
            end
          end
          # add interfaces to bond
          add_slave_list = @property_flush[:slaves] - runtime_slave_ports
          if !add_slave_list.empty?
            debug("Add '#{add_slave_list.join(',')}' ports to bond '#{@resource[:bond]}'")
            add_slave_list.each do |slave|
              debug("Add interface '#{slave}' to bond '#{@resource[:bond]}'")
              self.class.interface_down(slave)  # need by kernel requirements by design. undocumented :(
              self.class.set_sys_class("#{bond_prop_dir}/bonding/slaves", "+#{slave}")
              self.class.interface_up(slave)
            end
          end
        end
      end
      if @property_flush.has_key? :bond_properties
        bond_properties_to_change = @property_flush[:bond_properties]
        if @old_property_hash[:bond_properties] and !@old_property_hash[:bond_properties].empty?
          bond_properties_to_change = @property_flush[:bond_properties].to_a - @old_property_hash[:bond_properties].to_a
          bond_properties_to_change = Hash[*bond_properties_to_change.flatten]
        end
        debug("Bond properties which are going to be changed #{bond_properties_to_change}")
        # change bond_properties
        bond_is_up  = !self.class.get_iface_state(@resource[:bond]).nil?
        # Reassemble bond if we change bond mode
        need_reassembling = true if bond_properties_to_change[:mode] and self.class.get_sys_class("#{bond_prop_dir}/bonding/#{'mode'}") != bond_properties_to_change[:mode]
        if need_reassembling
          self.class.interface_down(@resource[:bond])
          bond_is_up = false
          runtime_slave_ports = self.class.get_sys_class("#{bond_prop_dir}/bonding/slaves", true)
          debug("Disassemble bond '#{@resource[:bond]}'")
          runtime_slave_ports.each do |eth|
            debug("Remove interface '#{eth}' from bond '#{@resource[:bond]}'")
            # for most bond options we should disassemble bond before re-configuration. In the kernel module documentation
            # says, that bond interface should be downed, but it's not enouth.
            self.class.set_sys_class("#{bond_prop_dir}/bonding/slaves", "-#{eth}")
          end
        end
        # setup primary bond_properties
        primary_bond_properties = [:mode, :xmit_hash_policy]
        debug("Set primary bond properties [#{primary_bond_properties.join(',')}] for bond '#{@resource[:bond]}'")
        primary_bond_properties.each do |ppp|
          pprop = ppp.to_s
          if bond_properties_to_change.has_key?(ppp)
            curr_pprop = self.class.get_sys_class("#{bond_prop_dir}/bonding/#{pprop}")
            should_pprop = bond_properties_to_change[ppp].to_s
            if ['', 'nil', 'undef'].include? should_pprop
              debug("Skip undefined property '#{pprop}'='#{should_pprop}' for bond '#{@resource[:bond]}'")
            elsif curr_pprop != should_pprop
              if bond_is_up
                self.class.interface_down(@resource[:bond])
                bond_is_up = false
              end
              debug("Setting #{pprop} '#/{should_pprop}' for bond '#{@resource[:bond]}'")
              self.class.set_sys_class("#{bond_prop_dir}/bonding/#{pprop}", should_pprop)
              sleep(1)
            else
              debug("Property #{pprop} already is '#{should_pprop}' for bond '#{@resource[:bond]}'. Nothing to do.")
            end
          end
        end
        # setup another bond_properties
        non_primary_bond_properties = bond_properties_to_change.reject{|k,v| primary_bond_properties.include? k}
        debug("Set non-primary bond properties [#{non_primary_bond_properties.keys.join(',')}] for bond '#{@resource[:bond]}'")
        non_primary_bond_properties.each do |prop, val|
          if ['', 'nil', 'undef'].include? val.to_s
            debug("Skip undefined property '#{prop}'='#{val}' for bond '#{@resource[:bond]}'")
          elsif self.class.lnx_bond_allowed_properties_list.include? prop.to_sym
            val_should_be = val.to_s
            val_actual = self.class.get_sys_class("#{bond_prop_dir}/bonding/#{prop}")
            if val_actual != val_should_be
              if bond_is_up
                self.class.interface_down(@resource[:bond])
                bond_is_up = false
              end
              debug("Setting property '#{prop}' to '#{val_should_be}' for bond '#{@resource[:bond]}'")
              self.class.set_sys_class("#{bond_prop_dir}/bonding/#{prop}", val_should_be)
            else
              debug("Property #{prop} already is '#{val_should_be}' for bond '#{@resource[:bond]}'. Nothing to do.")
            end
          else
            debug("Unsupported property '#{prop}' for bond '#{@resource[:bond]}'")
          end
        end
        if need_reassembling
          # re-assemble bond after configuration
          debug("Re-assemble bond '#{@resource[:bond]}'")
          runtime_slave_ports.each do |eth|
            debug("Add interface '#{eth}' to bond '#{@resource[:bond]}'")
            self.class.set_sys_class("#{bond_prop_dir}/bonding/slaves", "+#{eth}")
          end
        end
        self.class.interface_up(@resource[:bond]) if !bond_is_up
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
        bond_is_up  = !self.class.get_iface_state(@resource[:bond]).nil?
        if ! port_bridges_hash[@resource[:bond]].nil?
          br_name = port_bridges_hash[@resource[:bond]][:bridge]
          if br_name != @resource[:bond]
            if bond_is_up
              self.class.interface_down(@resource[:bond], true)
              bond_is_up = false
            end
            # do not remove bridge-based interface from his bridge
            case port_bridges_hash[@resource[:bond]][:br_type]
            when :ovs
              self.class.ovs_vsctl(['del-port', br_name, @resource[:bond]])
              # todo catch exception
            when :lnx
              self.class.brctl(['delif', br_name, @resource[:bond]])
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
            self.class.ovs_vsctl(['add-port', @property_flush[:bridge], @resource[:bond]])
          when :lnx
            self.class.brctl(['addif', @property_flush[:bridge], @resource[:bond]])
          else
            #pass
          end
        end
        self.class.interface_up(@resource[:bond]) if !bond_is_up
        debug("Change bridge")
      end
      if @property_flush[:onboot]
        self.class.interface_up(@resource[:bond]) if self.class.get_iface_state(@resource[:bond]).nil?
      end
      if !['', 'absent'].include? @property_flush[:mtu].to_s
        self.class.set_mtu(@resource[:bond], @property_flush[:mtu])
      end
      @property_hash = resource.to_hash
    end
  end

  #-----------------------------------------------------------------
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

end
# vim: set ts=2 sw=2 et :
