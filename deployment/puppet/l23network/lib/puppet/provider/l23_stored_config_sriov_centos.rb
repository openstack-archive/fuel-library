require File.join(File.dirname(__FILE__), '..','..','puppet/provider/l23_stored_config_centos')

class Puppet::Provider::L23_stored_config_sriov_centos < Puppet::Provider::L23_stored_config_centos

  def self.property_mappings
    rv = super
    rv.merge!({
      :sriov_numvfs => 'SRIOV_NUMFS',
      :device_type  => 'DEVICETYPE',
    })
    return rv
  end

  def if_type
    'sriov'
  end

  def device_type
    'sriov'
  end

  def self.mangle__sriov_numvfs(data)
    data.to_i
  end

  def self.unmangle__if_type(provider, val)
    val = val.to_s
    val
  end

  def self.unmangle__device_type(provider, val)
    val = val.to_s
    val
  end
end

# vim: set ts=2 sw=2 et :
