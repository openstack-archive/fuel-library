require 'puppetx/filemapper'
require File.join(File.dirname(__FILE__), '..','..','..','puppet/provider/l23_stored_config_centos6')

Puppet::Type.type(:l23_stored_config).provide(:ovs_centos6, :parent => Puppet::Provider::L23_stored_config_centos6) do

  include PuppetX::FileMapper

  confine :l23_os => :centos6

  has_feature :provider_options

  self.unlink_empty_files = true

  def self.property_mappings
    rv = super
    rv.merge!({
      :devicetype => 'DEVICETYPE',
    })
    return rv
  end

  def self.properties_fake
    rv = super
     rv.push(:devicetype)
    return rv
  end

  #Dirty hack which writes config files for OVS
  #bridges into /tmp directory
  def select_file
    if name == 'br-prv' or name == 'br-floating'
      "/tmp/ifcfg-#{name}"
    else
      "#{self.class.script_directory}/ifcfg-#{name}"
    end
  end

  def self.unmangle__if_type(provider, val)
    if val == :bridge
      val = :OVSBridge
    else
      val.to_s.capitalize.intern
    end
  end

  def self.mangle__if_type(val)
    if val == :OVSBridge
      val = :bridge
    else
      val.to_s.downcase.intern
    end
  end

  #Dirty hack which deletes OVS bridges from patch OVS
  #interfaces
  def self.unmangle__bridge(provider, val)
    if val.length == 2
      val.delete('br-prv') if val.include?('br-prv')
      val.delete('br-floating') if val.include?('br-floating')
      val
    end
  end

end
# vim: set ts=2 sw=2 et :
