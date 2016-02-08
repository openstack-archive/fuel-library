require File.join(File.dirname(__FILE__), '..','..','..','puppet/provider/ovs_base')

Puppet::Type.type(:l2_bond).provide(:ovs, :parent => Puppet::Provider::Ovs_base) do
  commands  :vsctl       => 'ovs-vsctl',
            :ethtool_cmd => 'ethtool'

  def self.instances
    bonds ||= self.get_ovs_bonds()
    debug("found bonds: #{bonds.keys}")
    rv = []
    bonds.each_pair do |bond_name, bond_props|
        props = {
          :ensure          => :present,
          :name            => bond_name,
          :vendor_specific => {}
        }
        props.merge! bond_props
        debug("PREFETCHED properties for '#{bond_name}': #{props}")
        rv << new(props)
    end
    rv
  end

  #-----------------------------------------------------------------

  def create
    debug("CREATE resource: #{@resource}")
    @old_property_hash = {}
    @property_flush = {}.merge! @resource

    @resource[:slaves].each do |slave|
      self.class.addr_flush(slave)
    end

    begin
      vsctl('--may-exist', 'add-bond', @resource[:bridge], @resource[:bond], @resource[:slaves])
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
      if @property_flush.has_key? :slaves and @old_property_hash.has_key? :slaves
        slaves_to_add = @property_flush[:slaves] - @old_property_hash[:slaves]
        debug("slaves to add #{slaves_to_add}") unless slaves_to_add.empty?
        slaves_to_remove = @old_property_hash[:slaves] - @property_flush[:slaves]
        debug("slaves to remove #{slaves_to_remove}") unless slaves_to_remove.empty?
        slaves_to_add.each do |slave|
         self.class.addr_flush(slave)
         vsctl("--id=@#{slave}", 'create', 'Interface', "name=#{slave}",
               '--', 'add', 'Port', @resource[:bond], 'interfaces', "@#{slave}")
        end
        slaves_to_remove.each do |slave|
         vsctl("--id=@#{slave}", 'get', 'Interface', slave,
               '--', 'remove', 'Port', @resource[:bond], 'interfaces', "@#{slave}")
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
      if @property_flush.has_key? :mtu
        debug("Do nothing, because for OVS bonds MTU can be changed only for slave interfaces.")
      end
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
