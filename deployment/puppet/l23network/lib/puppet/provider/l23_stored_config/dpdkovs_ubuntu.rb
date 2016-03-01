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
    elsif if_data[:if_type] =~ /dpdkovsbond/
        if_data[:if_type] = "bond"
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
      :bond_slaves    => 'ovs_bonds',
      :bond_mode      => 'ovs_options',
      :bond_miimon    => 'ovs_options',
      :bond_use_carrier => 'ovs_options',
      :bond_lacp_rate => 'ovs_options',
      :bond_lacp      => 'ovs_options',
      :bond_xmit_hash_policy => '', # unused
      :bond_ad_select => '',
      :bond_updelay   => 'ovs_options',
      :bond_downdelay => 'ovs_options',
    })
    return rv
  end

  def self.oneline_properties
    {
      :bond_mode => {
          :field    => 'bond_mode',
          :store_to => 'ovs_options'
      },
      :bond_updelay => {
          :field    => 'bond_updelay',
          :store_to => 'ovs_options'
      },
      :bond_downdelay => {
          :field    => 'bond_downdelay',
          :store_to => 'ovs_options'
      },
      :bond_lacp => {
          :field    => 'lacp',
          :store_to => 'ovs_options'
      },
      :bond_lacp_rate  => {
          :field    => 'other_config:lacp-time',
          :store_to => 'ovs_options'
      },
      :bond_miimon  => {
          :field    => 'other_config:bond-miimon-interval',
          :store_to => 'ovs_options'
      },
      :bond_use_carrier  => {
          :field    => 'other_config:bond-detect-mode',
          :store_to => 'ovs_options'
      },
    }
  end
  def oneline_properties
    self.class.collected_properties
  end
  def self.iface_file_header(provider)
    header = []
    props  = {}
    bridge = provider.bridge[0]
    props[:bridge] = bridge
    header << self.puppet_header
    header << "allow-#{bridge} #{provider.name}"
    header << "iface #{provider.name} inet #{provider.method}"
    return header, props
  end

  def dpdk_port
    dpdk_ports = self.class.get_dpdk_ports_mapping
    dpdk_port = dpdk_ports[self.name]
  end

  def self.mangle__bond_slaves(val)
    ports_dpdk_mapping = self.get_dpdk_ports_mapping.invert
    val.split(/[\s,]+/).map {|i| ports_dpdk_mapping[i]}.sort
  end

  def self.unmangle__bond_slaves(provider, val)
    dpdk_ports_mapping = self.get_dpdk_ports_mapping
    if val.size < 1 or [:absent, :undef].include? Array(val)[0].to_sym
      nil
    else
      val.map {|i| dpdk_ports_mapping[i]}.sort.join(' ')
    end
  end

  def self.unmangle__bond_use_carrier(provider, data)
    values = [ 'miimon', 'carrier' ]
    rv = values[data.to_i] if data.to_i <= values.size
    rv ||= nil
  end

  def self.unmangle__if_type(provider, val)
    val = 'DPDKOVSPort' if val.to_s == 'ethernet'
    val = 'DPDKOVSBond' if val.to_s == 'bond'
    val
  end
end

# vim: set ts=2 sw=2 et :