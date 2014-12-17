require 'puppetx/filemapper'
require File.join(File.dirname(__FILE__), '..','..','..','puppet/provider/l23_stored_config_ubuntu')

Puppet::Type.type(:l23_stored_config).provide(:lnx_ubuntu, :parent => Puppet::Provider::L23_stored_config_ubuntu) do

  include PuppetX::FileMapper

  confine    :l23_os => :ubuntu
  defaultfor :l23_os => :ubuntu

  has_feature :provider_options
  #has_feature :hotpluggable

  self.unlink_empty_files = true

end
