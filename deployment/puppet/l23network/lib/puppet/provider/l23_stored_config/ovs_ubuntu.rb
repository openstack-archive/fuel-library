require 'puppetx/filemapper'
require File.join(File.dirname(__FILE__), '..','..','..','puppet/provider/l23_stored_config_ubuntu')

Puppet::Type.type(:l23_stored_config).provide(:ovs_ubuntu, :parent => Puppet::Provider::L23_stored_config_ubuntu) do

  include PuppetX::FileMapper

  has_feature :provider_options

  self.unlink_empty_files = true

  def self.property_mappings
    rv = super
    rv.merge!({
      :ovs_type   => 'ovs_type',
      :ovs_bridge => 'ovs_bridge',
    })
    return rv
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


    # Add onboot interfaces
    if provider.onboot
      header << "auto #{provider.name}"
    end

    bridge = provider.bridge[0]
    if provider.if_type.to_s == 'bridge'
      header << "allow-ovs #{provider.name}"
      props[:bridge_ports] = nil
      props[:ovs_type] = 'OVSBridge'
      props[:ovs_bridge] = nil
    elsif provider.if_type.to_s == 'bond'
      props[:ovs_type] = 'OVSBond'
      props[:ovs_bridge] = bridge
    else
      header << "allow-#{bridge} #{provider.name}"
      props[:ovs_type] = 'OVSIntPort'
      props[:ovs_bridge] = bridge
    end
    # Add iface header
    header << "iface #{provider.name} inet #{provider.method}"

    return header, props
  end



  def self.mangle__type(val)
    :ethernet
  end
  def self.unmangle__type(val)
    nil
  end

end
# vim: set ts=2 sw=2 et :