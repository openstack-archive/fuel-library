require File.join(File.dirname(__FILE__), 'l2_base')

class Puppet::Provider::Lnx_base < Puppet::Provider::L2_base

  #todo(sv): adapt this to LNX resources
  # def self.instances
  #   rv = []
  #   get_instances(ovs_vsctl_show()).each_pair do |p_name, p_props|
  #     props = {
  #       :ensure          => :present,
  #       :name            => p_name,
  #       :vendor_specific => {}
  #     }
  #     debug("prefetching '#{p_name}'")
  #     props.merge! p_props
  #     next if skip_port_for? props
  #     add_unremovable_flag(props)
  #     ##add PROVIDER prefix to port type flags and create puppet resource
  #     if props[:provider] == 'ovs'
  #       props[:port_type] = props[:port_type].insert(0, 'ovs').join(':')
  #       rv << new(props)
  #       debug("PREFETCH properties for '#{p_name}': #{props}")
  #     else
  #       debug("SKIP properties for '#{p_name}': #{props}")
  #     end
  #   end
  #   return rv
  # end


  def initialize(value={})
    super(value)
    @property_flush = {}
    @old_property_hash = {}
    @old_property_hash.merge! @property_hash
  end

  def exists?
    @property_hash[:ensure] == :present
  end

  #-----------------------------------------------------------------
  def vendor_specific
    @property_hash[:vendor_specific] || :absent
  end
  def vendor_specific=(val)
    nil
  end

  def mtu
    @property_hash[:mtu] || :absent
  end
  def mtu=(val)
    # for MTU :absent is sinonym of 'do not change'
    @property_flush[:mtu] = val.to_i if !['', 'absent'].include? val.to_s
  end

  def onboot
    @property_hash[:onboot] || :absent
  end
  def onboot=(val)
    @property_flush[:onboot] = val
  end

  def bridge
    @property_hash[:bridge] || :absent
  end
  def bridge=(val)
    @property_flush[:bridge] = val
  end

  def ethtool
    @property_hash[:ethtool] || nil
  end
  def ethtool=(val)
    @property_flush[:ethtool] = val
  end

  def port_type
    @property_hash[:port_type] || :absent
  end
  def port_type=(val)
    @property_flush[:port_type] = val
  end

  def type
    :absent
  end
  def type=(value)
    debug("Resource '#{@resource[:name]}': Doesn't support interface type change.")
  end

end
# vim: set ts=2 sw=2 et :