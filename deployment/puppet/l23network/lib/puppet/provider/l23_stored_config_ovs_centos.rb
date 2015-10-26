require File.join(File.dirname(__FILE__), '..','..','puppet/provider/l23_stored_config_centos')

class Puppet::Provider::L23_stored_config_ovs_centos < Puppet::Provider::L23_stored_config_centos

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
    "OVS#{val.to_s.capitalize}".to_sym
  end

  def self.mangle__if_type(val)
    val.gsub('OVS', '').downcase.to_sym
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
