require_relative '../../../puppetx/filemapper_loader'
require_relative '../l23_stored_config_ubuntu'

Puppet::Type.type(:l23_stored_config).provide(:lnx_ubuntu, :parent => Puppet::Provider::L23_stored_config_ubuntu) do

  include PuppetX::FileMapper

  confine    :l23_os => :ubuntu
  defaultfor :l23_os => :ubuntu

  has_feature :provider_options
  #has_feature :hotpluggable

  self.unlink_empty_files = true

  def self.check_if_provider(if_data)
    if if_data[:if_provider] =~ /lnx/
        if_data[:if_provider] = :lnx
        true
    else
        if_data[:if_provider] = nil
        false
    end
  end

  def self.iface_file_header(provider)
    rv = []

    rv << self.puppet_header

    # Add onboot interfaces
    if provider.onboot
      rv << "auto #{provider.name}"
    end

    # Add iface header
    rv << "iface #{provider.name} inet #{provider.method}"

    return rv, {}
  end

end
# vim: set ts=2 sw=2 et :
