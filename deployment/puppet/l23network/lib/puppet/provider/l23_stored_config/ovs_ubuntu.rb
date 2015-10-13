require 'puppetx/filemapper'
require File.join(File.dirname(__FILE__), '..','..','..','puppet/provider/l23_stored_config_ubuntu')

Puppet::Type.type(:l23_stored_config).provide(:ovs_ubuntu, :parent => Puppet::Provider::L23_stored_config_ubuntu) do

  include PuppetX::FileMapper

  confine    :l23_os => :ubuntu
  defaultfor :l23_os => :ubuntu

  has_feature :provider_options

  self.unlink_empty_files = true

  def self.property_mappings
    rv = super
    rv.merge!({
      #todo(sv): :onboot         => '', # should not be used (may be if no ipaddr)
      :ovs_type       => 'ovs_type',
      :bridge         => 'ovs_bridge',
      :bridge_ports   => 'ovs_ports',
      :bond_slaves    => 'ovs_bonds',
      :bond_mode      => 'ovs_options',
      :bond_miimon    => 'ovs_options',
      :bond_lacp_rate => 'ovs_options',
      :bond_lacp      => 'ovs_options',
      :bond_xmit_hash_policy => '', # unused
      :bond_ad_select => '',
      :bond_updelay   => 'ovs_options',
      :bond_downdelay => 'ovs_options',
    })
    return rv
  end

  # Some properties can be defined as repeatable key=value string part in the
  # one option in config file these properties should be fetched by RE-scanning
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
    }
  end
  def oneline_properties
    self.class.collected_properties
  end


  def self.check_if_provider(if_data)
    if if_data[:if_provider].to_s =~ /ovs/
        if_data[:if_provider] = :ovs
        true
    else
        if_data[:if_provider] = nil
        false
    end
  end

  def self.iface_file_header(provider)
    header = []
    props  = {}

    bridge = provider.bridge[0]
    if provider.if_type.to_s == 'bridge'
      header << "auto #{provider.name}" if provider.onboot
      header << "allow-ovs #{provider.name}"
      props[:ovs_type] = 'OVSBridge'
      props[:bridge]   = nil
    elsif provider.if_type.to_s == 'bond'
      # there are no 'auto bond-name' should be here. Because!
      header << "allow-#{bridge} #{provider.name}"
      props[:ovs_type] = 'OVSBond'
      props[:bridge]   = bridge
    elsif provider.if_type.to_s == 'patch'
      header << "auto #{provider.name}" if provider.onboot
      header << "allow-#{bridge} #{provider.name}"
      props[:bridge]   = bridge
      props[:ovs_type] = 'OVSPort'
      provider.mtu     = nil
    else
      header << "auto #{provider.name}" if provider.onboot
      header << "allow-#{bridge} #{provider.name}"
      props[:ovs_type] = 'OVSIntPort'
      props[:bridge]   = bridge
      provider.jacks   = nil
    end
    # Add iface header
    header << "iface #{provider.name} inet #{provider.method}"

    return header, props
  end

  def self.collected_properties
    rv = super
    rv.merge!({
      :jacks  => {
          :detect_re    => /(ovs_)?extra\s+--\s+set\s+Interface\s+(p_.*-[0 1])\s+type=patch\s+options:peer=(p_.*-[0 1])/,
          :detect_shift => 3,
      },
      :vlan_id  => {
          :detect_re    => /(ovs_)?extra\s+--\s+set\s+Port\s+(p_.*-[0 1])\s+tag=(\d+)/,
          :detect_shift => 3,
      },
    })
    return rv
  end

  def self.unmangle__jacks(provider, data)
    rv = []
    rv << "ovs_extra -- set Interface #{provider.name} type=patch options:peer=#{data.join()}"
  end

  def self.unmangle__vlan_id(provider, data)
    rv = []
    rv << "ovs_extra -- set Port #{provider.name} tag=#{provider.vlan_id}"
  end

  def self.mangle__jacks(data)
    [data.join()]
  end

  def self.mangle__vlan_id(data)
    data.join()
  end

end
# vim: set ts=2 sw=2 et :
