require 'puppetx/filemapper'
require File.join(File.dirname(__FILE__), '..','..','..','puppet/provider/l23_stored_config_ubuntu')

Puppet::Type.type(:l23_stored_config).provide(:ovs_ubuntu, :parent => Puppet::Provider::L23_stored_config_ubuntu) do

  include PuppetX::FileMapper

  confine :l23_os => :ubuntu

  has_feature :provider_options

  self.unlink_empty_files = true


  def self.mangle__method(val)
    :manual
  end

  def self.mangle__type(val)
    :ethernet
  end
  def self.unmangle__type(val)
    nil
  end

end
