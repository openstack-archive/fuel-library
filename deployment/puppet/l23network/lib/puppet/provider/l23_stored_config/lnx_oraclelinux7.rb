require 'puppetx/filemapper'
require File.join(File.dirname(__FILE__), '..','..','..','puppet/provider/l23_stored_config_centos')

Puppet::Type.type(:l23_stored_config).provide(:lnx_oraclelinux7, :parent => Puppet::Provider::L23_stored_config_centos) do

  include PuppetX::FileMapper

  confine    :l23_os => :oraclelinux7
  defaultfor :l23_os => :oraclelinux7

  has_feature :provider_options

  self.unlink_empty_files = true

end
# vim: set ts=2 sw=2 et :
