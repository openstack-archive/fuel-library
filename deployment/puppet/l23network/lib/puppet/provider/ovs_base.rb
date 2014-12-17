require File.join(File.dirname(__FILE__), 'l2_base')

class Puppet::Provider::Ovs_base < Puppet::Provider::L2_base

  def self.skip_port_for?(port_props)
    # calculate whether this port should be skipped.
    # Should be re-defined in chield providers
    false
  end

  def self.add_unremovable_flag(port_props)
    # calculate 'unremovable' flag. Should be re-defined in chield providers
    true
  end

  def self.get_instances(big_hash)
    # calculate hash of hashes from given big hash
    # Should be re-defined in chield providers
    {}
  end

  def self.instances
    rv = []
    get_instances(ovs_vsctl_show()).each_pair do |p_name, p_props|
      props = {
        :ensure          => :present,
        :name            => p_name,
        :vendor_specific => {}
      }
      debug("prefetching '#{p_name}'")
      props.merge! p_props
      next if skip_port_for? props
      add_unremovable_flag(props)
      ##add PROVIDER prefix to port type flags and create puppet resource
      if props[:provider] == 'ovs'
        props[:port_type] = props[:port_type].insert(0, 'ovs').join(':')
        rv << new(props)
        debug("PREFETCH properties for '#{p_name}': #{props}")
      else
        debug("SKIP properties for '#{p_name}': #{props}")
      end
    end
    return rv
  end


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
  #-----------------------------------------------------------------
  def bridge
    @property_hash[:bridge] || :absent
  end
  def bridge=(val)
    @property_flush[:bridge] = val
  end

  def vlan_dev
    :absent
  end
  def vlan_dev=(val)
    nil
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
    'vlan'
  end
  def vlan_mode=(val)
    nil
  end

  def bond_master
    :absent
  end
  def bond_master=(val)
    nil
  end

  def slaves
    @property_hash[:slaves] || :absent
  end
  def slaves=(val)
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

  def vendor_specific
    @property_hash[:vendor_specific] || :absent
  end
  def vendor_specific=(val)
    @property_flush[:vendor_specific] = val
  end

  def type
    @property_hash[:type] || :absent
  end
  def type=(value)
    @property_flush[:type] = val
  end

  #-----------------------------------------------------------------

end
# vim: set ts=2 sw=2 et :