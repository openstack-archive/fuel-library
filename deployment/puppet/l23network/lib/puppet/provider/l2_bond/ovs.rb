require File.join(File.dirname(__FILE__), '..','..','..','puppet/provider/ovs_base')

Puppet::Type.type(:l2_bond).provide(:ovs, :parent => Puppet::Provider::Ovs_base) do
  commands  :vsctl       => 'ovs-vsctl',
            :ethtool_cmd => 'ethtool',
            :iproute     => 'ip'


  # def self.add_unremovable_flag(port_props)
  #   # calculate 'unremovable' flag. Should be re-defined in chield providers
  #   if port_props[:port_type].include? 'bridge' or port_props[:port_type].include? 'bond'
  #     port_props[:port_type] << 'unremovable'
  #   end
  # end

  def self.get_instances(big_hash)
    # didn't use .select{...} here for backward compatibility with ruby 1.8
    big_hash[:port].reject{|k,v| !v[:port_type].include?('bond')}
  end

  #-----------------------------------------------------------------

  def create
    debug("CREATE resource: #{@resource}")
    @old_property_hash = {}
    @property_flush = {}.merge! @resource

    @resource[:slaves].each do |slave|
      iproute('addr', 'flush', 'dev', slave)
    end

    begin
      vsctl('--may-exist', 'add-bond', @resource[:bridge], @resource[:bond], @resource[:slaves])
    rescue Puppet::ExecutionFailure => error
      raise Puppet::ExecutionFailure, "Can't add bond '#{@resource[:bond]}'\n#{error}"
    end
    # # set interface properties
    # if @resource[:interface_properties]
    #   for option in @resource[:interface_properties]
    #     begin
    #       vsctl('--', "set", "Interface", @resource[:interface], option.to_s)
    #     rescue Puppet::ExecutionFailure => error
    #       raise Puppet::ExecutionFailure, "Interface '#{@resource[:interface]}' can't set option '#{option}':\n#{error}"
    #     end
    #   end
    # end
  end

  def destroy
    vsctl('del-port', @resource[:bridge], @resource[:bond])
  end

  def flush
    if ! @property_flush.empty?
      debug("FLUSH properties: #{@property_flush}")
      if @property_flush.has_key? :slaves
        warn("Do nothing, OVS don't allow change bond slaves for existing bond ('#{@resource[:bond]}').")
        # But we can implement this undocumented hack later
        #   ovs-vsctl add-port br3 ee2
        #   ovs-vsctl list interface ee2  # get uuid for port
        #   ovs-vsctl -- set port bond3 'interfaces=[0e6a0107-d0c7-49a6-93c7-41fe23e61c2c, 2c21e847-05ea-4b11-bde2-bb19e2d0ca56]'
        #   ovs-vsctl show
        #   ovs-vsctl del-port ee2  # ignore error
        #   ovs-vsctl show
      end
      if @property_flush.has_key? :bond_properties
        # change bond_properties
        allowed_properties = self.class.ovs_bond_allowed_properties()
        @property_flush[:bond_properties].each_pair do |prop, val|
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
