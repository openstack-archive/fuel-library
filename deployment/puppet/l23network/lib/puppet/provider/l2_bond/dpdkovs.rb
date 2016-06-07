require_relative '../ovs_base'
require_relative '../../../puppetx/l23_dpdk_ports_mapping'

Puppet::Type.type(:l2_bond).provide(:dpdkovs, :parent => Puppet::Provider::Ovs_base) do
  commands  :vsctl       => 'ovs-vsctl',
            :ethtool_cmd => 'ethtool'

  def self.get_dpdk_ports_mapping
    L23network.get_dpdk_ports_mapping
  end

  def self.instances
    ports_dpdk_mapping = self.get_dpdk_ports_mapping.invert

    bonds ||= self.get_ovs_bonds
    debug("found bonds: #{bonds.keys}")
    rv = []
    bonds.each_pair do |bond_name, bond_props|
        props = {
          :ensure          => :present,
          :name            => bond_name,
          :vendor_specific => {}
        }
        props.merge! bond_props
        props[:slaves] = bond_props[:slaves].map do |slave|
          raise Puppet::ExecutionFailure, "Can't find port '#{slave}'" unless ports_dpdk_mapping[slave]
          ports_dpdk_mapping[slave]
        end
        debug("PREFETCHED properties for '#{bond_name}': #{props}")
        rv << new(props)
    end
    rv
  end

  #-----------------------------------------------------------------

  def create
    debug("CREATE resource: #{@resource}")
    @old_property_hash = {}

    dpdk_ports = self.class.get_dpdk_ports_mapping
    @resource[:slaves] = @resource[:slaves].map do |slave|
      raise Puppet::ExecutionFailure, "Can't find port '#{slave}'" unless dpdk_ports[slave]
      dpdk_ports[slave]
    end

    @property_flush = {}.merge! @resource

    iface_props = @resource[:slaves].reduce([]) do |rv, slave|
      rv.concat(['--', 'set', 'Interface', slave, 'type=dpdk'])
    end

    begin
      vsctl('--may-exist', 'add-bond', @resource[:bridge], @resource[:bond], @resource[:slaves], iface_props)
    rescue Puppet::ExecutionFailure => error
      raise Puppet::ExecutionFailure, "Can't add bond '#{@resource[:bond]}'\n#{error}"
    end
  end

  def destroy
    vsctl('del-port', @resource[:bridge], @resource[:bond])
  end

  def flush
    if ! @property_flush.empty?
      debug("FLUSH properties: #{@property_flush}")
      if @property_flush.has_key?(:slaves) && @old_property_hash.has_key?(:slaves)
        slaves_to_add = (@property_flush[:slaves] - @old_property_hash[:slaves])
        debug("slaves to add #{slaves_to_add}") unless slaves_to_add.empty?
        slaves_to_remove = (@old_property_hash[:slaves] - @property_flush[:slaves])
        debug("slaves to remove #{slaves_to_remove}") unless slaves_to_remove.empty?
        if slaves_to_add || slaves_to_remove
          raise(Puppet::ExecutionFailure, "Can't change bond slaves '#{@resource[:bond]}'")
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
        allowed_properties = self.class.ovs_bond_allowed_properties()
        bond_properties_to_change.each_pair do |prop, val|
          if self.class.ovs_bond_allowed_properties_list.include? prop.to_sym
            act_val = val.to_s
          else
            warn("Unsupported property '#{prop}' for bond '#{@resource[:bond]}'")
            next
          end
          next if ['','none', 'undef', 'absent', 'nil'].include? act_val
          debug("Set property '#{prop}' to '#{act_val}' for bond '#{@resource[:bond]}'")
          if allowed_properties[prop.to_sym][:property]
            # just setup property in OVSDB
            if allowed_properties[prop.to_sym][:allow] and ! allowed_properties[prop.to_sym][:allow].include? val
              warn("Unsupported value '#{val}' for property '#{prop}' for bond '#{@resource[:bond]}'.\nAllowed modes: #{allowed_properties[prop.to_sym][:allow]}")
              val = nil
            end
            if allowed_properties[prop.to_sym][:override_integer]
              # override property if it should be given as string for ovs and as integer for native linux
              val = allowed_properties[prop.to_sym][:override_integer][val.to_i] || allowed_properties[prop.to_sym][:override_integer][0]
            end
            vsctl('--', 'set', 'Port', @resource[:bond], "#{allowed_properties[prop.to_sym][:property]}=#{val}") if ! val.nil?
          end
        end
      end
      #
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
