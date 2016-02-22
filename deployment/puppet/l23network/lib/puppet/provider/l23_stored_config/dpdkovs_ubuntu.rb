require 'puppetx/filemapper'
require 'puppetx/l23_dpdk_ports_mapping'
require File.join(File.dirname(__FILE__), '..','..','..','puppet/provider/l23_stored_config_ubuntu')

Puppet::Type.type(:l23_stored_config).provide(:dpdkovs_ubuntu, :parent => Puppet::Provider::L23_stored_config_ubuntu) do

  include PuppetX::FileMapper

  confine    :l23_os => :ubuntu

  has_feature :provider_options

  self.unlink_empty_files = true

  def self.get_dpdk_ports_mapping
    L23network.get_dpdk_ports_mapping
  end

  def self.check_if_provider(if_data)
    if if_data[:if_type] =~ /dpdkovsport/
        if_data[:if_type] = "ethernet"
        if_data[:if_provider] = :dpdkovs
        true
    else
        if_data[:if_provider] = nil
        false
    end
  end

  def self.property_mappings
    rv = super
    rv.merge!({
      :if_type        => 'ovs_type',
      :bridge         => 'ovs_bridge',
      :dpdk_port      => 'dpdk_port',
    })
    return rv
  end

  def self.iface_file_header(provider)
    header = []
    props  = {}

    ports = self.get_dpdk_ports_mapping()
    dpdk_port = ports.map { |i,p| i if p[:interface] == provider.name}.compact[0]

    bridge = provider.bridge[0]
    props[:bridge] = bridge
    props[:dpdk_port] = dpdk_port

    header << self.puppet_header
    header << "allow-#{bridge} #{provider.name}"
    header << "iface #{provider.name} inet #{provider.method}"
    header << "pre-up ovs-vsctl --may-exist add-port ${IF_OVS_BRIDGE} ${IF_DPDK_PORT} -- ${IF_OVS_EXTRA}"
    header << "ovs_extra set Interface #{dpdk_port} type=dpdk"
    return header, props
  end

  def self.unmangle__if_type(provider, val)
    val = 'DPDKOVSPort' if val.to_s == 'ethernet'
    val
  end
end

# vim: set ts=2 sw=2 et :