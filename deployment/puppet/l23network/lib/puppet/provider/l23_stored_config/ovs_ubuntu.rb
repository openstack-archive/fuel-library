require 'puppetx/filemapper'
require File.join(File.dirname(__FILE__), '..','..','..','puppet/provider/l23_stored_config_ubuntu')

Puppet::Type.type(:l23_stored_config).provide(:ovs_ubuntu, :parent => Puppet::Provider::L23_stored_config_ubuntu) do

  include PuppetX::FileMapper

  has_feature :provider_options

  self.unlink_empty_files = true

  # def self.property_mappings
  #   rv = super
  #   rv.merge!({
  #     :onboot => 'allow-ovs'
  #   })
  #   return rv
  # end

  def self.check_if_provider(if_data)
    if if_data[:if_provider] =~ /allow-\S/
        if_data[:if_provider] = :ovs
        true
    else
        if_data[:if_provider] = nil
        false
    end
  end

  def self.iface_file_header(provider)
    rv = []

    # Add onboot interfaces
    if provider.onboot
      rv << "auto #{provider.name}"
    end

    bridge = provider.bridge[0]
    if provider.if_type.to_s == 'bridge'
      rv << "allow-ovs #{provider.name}"
    else
      rv << "allow-#{bridge} #{provider.name}"
    end
    # Add iface header
    rv << "iface #{provider.name} inet #{provider.method}"

    return rv
  end



  def self.mangle__type(val)
    :ethernet
  end
  def self.unmangle__type(val)
    nil
  end

end
# vim: set ts=2 sw=2 et :