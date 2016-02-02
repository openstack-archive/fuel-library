require 'puppetx/filemapper'
require File.join(File.dirname(__FILE__), '..','..','..','puppet/provider/l23_stored_config_ubuntu')

Puppet::Type.type(:l23_stored_config).provide(:sriov_ubuntu, :parent => Puppet::Provider::L23_stored_config_ubuntu) do

  include PuppetX::FileMapper

  confine    :l23_os => :ubuntu
  defaultfor :l23_os => :ubuntu

  has_feature :provider_options
  #has_feature :hotpluggable

  self.unlink_empty_files = true

  def self.check_if_provider(if_data)
    if if_data[:if_provider] =~ /sriov/
        if_data[:if_provider] = :sriov
        true
    else
        if_data[:if_provider] = nil
        false
    end
  end

  def self.iface_file_header(provider)
    rv = []

    rv << self.puppet_header

    rv << "allow-sriov #{provider.name}"

    # Add onboot interfaces
    if provider.onboot
      rv << "auto #{provider.name}"
    end

    # Add iface header
    rv << "iface #{provider.name} inet #{provider.method}"

    return rv, {}
  end

  def self.collected_properties
    rv = super
    rv.merge!({
                  :vendor_specific  => {
                      :detect_re    => /up\s+echo\s+(\d+)\s+>\s*\/sys\/class\/net\/([^\/]+)\/device\/sriov_numvfs/,
                      :detect_shift => 1,
                  },
              })
    return rv
  end

  def self.unmangle__vendor_specific(provider, data)
    rv = []
    rv << "up echo #{data["sriov_numvfs"]} > /sys/class/net/#{provider.name}/device/sriov_numvfs"
  end

  def self.mangle__vendor_specific(data)
    {
        :sriov_numvfs => data[0][0].to_i
    }
  end
end
# vim: set ts=2 sw=2 et :
