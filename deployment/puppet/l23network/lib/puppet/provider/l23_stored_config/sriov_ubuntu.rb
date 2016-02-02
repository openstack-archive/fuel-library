require 'puppetx/filemapper'
require File.join(File.dirname(__FILE__), '..','..','..','puppet/provider/l23_stored_config_ubuntu')

Puppet::Type.type(:l23_stored_config).provide(:sriov_ubuntu, :parent => Puppet::Provider::L23_stored_config_ubuntu) do

  include PuppetX::FileMapper

  confine    :l23_os => :ubuntu

  has_feature :provider_options

  self.unlink_empty_files = true

  def self.check_if_provider(if_data)
    if if_data[:sriov_numvfs]
      if_data[:if_provider] = :sriov
      true
    else
      if_data[:if_provider] = nil
    end
  end

  def self.property_mappings
    super.merge({
      :sriov_numvfs => 'sriov_numvfs',
    })
  end

  def self.iface_file_header(provider)
    rv = []

    rv << self.puppet_header

    if provider.onboot
      rv << "auto #{provider.name}"
    end

    rv << "iface #{provider.name} inet #{provider.method}"
    rv << "up echo 0 > /sys/class/net/#{provider.name}/device/sriov_numvfs"
    rv << "up echo ${IF_SRIOV_NUMVFS:-0} > /sys/class/net/#{provider.name}/device/sriov_numvfs"

    return [rv, {}]
  end

  def self.mangle__sriov_numvfs(data)
    data.to_i
  end
end

# vim: set ts=2 sw=2 et :