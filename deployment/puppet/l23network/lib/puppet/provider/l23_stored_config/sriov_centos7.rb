require 'puppetx/filemapper'
require File.join(File.dirname(__FILE__), '..','..','..','puppet/provider/l23_stored_config_ovs_centos')

Puppet::Type.type(:l23_stored_config).provide(:sriov_centos7, :parent => Puppet::Provider::L23_stored_config_ovs_centos) do

  include PuppetX::FileMapper

  confine    :l23_os => :centos7

  has_feature :provider_options

  self.unlink_empty_files = true

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
