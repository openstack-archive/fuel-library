require 'puppetx/filemapper'
require File.join(File.dirname(__FILE__), '..','..','..','puppet/provider/l23_stored_config_ubuntu')

Puppet::Type.type(:l23_stored_config).provide(:lnx_ubuntu, :parent => Puppet::Provider::L23_stored_config_ubuntu) do

  include PuppetX::FileMapper

  defaultfor :l23_os => :ubuntu

  has_feature :provider_options
  #has_feature :hotpluggable

  self.unlink_empty_files = true

  def self.check_if_provider(if_data)
    if if_data[:if_provider] == 'auto'
        if_data[:if_provider] = :lnx
        true
    else
        if_data[:if_provider] = nil
        false
    end
  end

end
# vim: set ts=2 sw=2 et :