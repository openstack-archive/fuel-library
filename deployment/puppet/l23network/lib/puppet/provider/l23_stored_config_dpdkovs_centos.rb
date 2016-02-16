require 'puppetx/l23_dpdk_ports_mapping'
require File.join(File.dirname(__FILE__), '..','..','puppet/provider/l23_stored_config_centos')

class Puppet::Provider::L23_stored_config_dpdkovs_centos < Puppet::Provider::L23_stored_config_centos

  def self.get_dpdk_ports_mapping
    L23network.get_dpdk_ports_mapping
  end

  def self.property_mappings
    rv = super
    rv.merge!({
      :devicetype => 'DEVICETYPE',
      :bridge     => 'OVS_BRIDGE',
      :dpdk_port  => 'DPDK_PORT',
    })
    return rv
  end

  def self.unmangle__if_type(provider, val)
    val = 'DPDKOVSPort' if val.to_s == 'ethernet'
    val
  end
end

# vim: set ts=2 sw=2 et :
