require 'puppetx/filemapper'
require File.join(File.dirname(__FILE__), '..','..','..','puppet/provider/l23_stored_config_ubuntu')

Puppet::Type.type(:l23_stored_config).provide(:ovs_ubuntu, :parent => Puppet::Provider::L23_stored_config_ubuntu) do

  include PuppetX::FileMapper

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
    else
      header << "auto #{provider.name}" if provider.onboot
      header << "allow-#{bridge} #{provider.name}"
      props[:ovs_type] = 'OVSIntPort'
      props[:bridge]   = bridge
    end
    # Add iface header
    header << "iface #{provider.name} inet #{provider.method}"

    return header, props
  end

end
# vim: set ts=2 sw=2 et :