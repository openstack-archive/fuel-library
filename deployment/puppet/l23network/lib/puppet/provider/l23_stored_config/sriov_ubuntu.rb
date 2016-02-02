require 'puppetx/filemapper'
require File.join(File.dirname(__FILE__), '..','..','..','puppet/provider/l23_stored_config_ubuntu')

Puppet::Type.type(:l23_stored_config).provide(:sriov_ubuntu, :parent => Puppet::Provider::L23_stored_config_ubuntu) do

  include PuppetX::FileMapper

  confine    :l23_os => :ubuntu

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
    rv << "up echo 0 > /sys/class/net/#{provider.name}/device/sriov_numvfs"

    return rv, {}
  end

  def self.collected_properties
    rv = super
    rv.merge!({
                  :sriov_numvfs  => {
                      :detect_re    => /up\s+echo\s+([1-9]+\d*)\s+>\s*\/sys\/class\/net\/([^\/]+)\/device\/sriov_numvfs/,
                      :detect_shift => 1,
                  },
              })
    return rv
  end

  def self.unmangle__sriov_numvfs(provider, data)
    if data
     sriov_numvfs = data.to_s.to_i
     if sriov_numvfs > 0
        rv = []
        rv << "up echo #{sriov_numvfs} > /sys/class/net/#{provider.name}/device/sriov_numvfs"
      end
    end
  end

  def self.mangle__sriov_numvfs(data)
    data[0][0].to_i
  end
end
# vim: set ts=2 sw=2 et :
