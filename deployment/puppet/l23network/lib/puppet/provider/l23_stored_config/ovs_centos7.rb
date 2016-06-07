require_relative '../../../puppetx/filemapper_loader'
require_relative '../l23_stored_config_ovs_centos'

Puppet::Type.type(:l23_stored_config).provide(:ovs_centos7, :parent => Puppet::Provider::L23_stored_config_ovs_centos) do

  include PuppetX::FileMapper

  confine    :l23_os => :centos7

  has_feature :provider_options

  self.unlink_empty_files = true

end

# vim: set ts=2 sw=2 et :
