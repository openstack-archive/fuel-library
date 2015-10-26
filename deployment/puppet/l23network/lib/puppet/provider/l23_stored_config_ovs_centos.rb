require File.join(File.dirname(__FILE__), '..','..','puppet/provider/l23_stored_config_centos')

class Puppet::Provider::L23_stored_config_ovs_centos < Puppet::Provider::L23_stored_config_centos

  def self.property_mappings
    rv = super
    rv.merge!({
      :devicetype   => 'DEVICETYPE',
      :bonding_opts => 'OVS_OPTIONS',
      :bridge       => 'OVS_BRIDGE',
      :bond_slaves  => 'BOND_IFACES',
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

  def self.format_bond_opts(props)
    props[:devicetype] = 'ovs'
    bond_options = "bond_mode=#{props[:bond_mode]} other_config:bond-miimon-interval=#{props[:bond_miimon]}"
    if props.has_key?(:bond_lacp_rate)
      bond_options = "#{bond_options} lacp_rate=#{props[:bond_lacp_rate]}"
      props.delete(:bond_lacp_rate)
    end
    if props.has_key?(:bond_xmit_hash_policy)
      bond_options = "#{bond_options} xmit_hash_policy=#{props[:bond_xmit_hash_policy]}"
      props.delete(:bond_xmit_hash_policy)
    end
    props[:bonding_opts]  = "\"#{bond_options}\""
    props.delete(:bond_mode)
    props.delete(:bond_miimon)
    props
  end

  def self.unmangle__if_type(provider, val)
    "OVS#{val.to_s.capitalize}".to_sym
  end

  def self.mangle__if_type(val)
    val.gsub('OVS', '').downcase.to_sym
  end

  def self.unmangle__bond_slaves(provider, val)
    val.select!{ |x| x.to_s != 'absent' }
    "\"#{val.join(' ')}\""
  end

  def self.mangle__bond_slaves(val)
    val.split(' ')
  end


  #Dirty hack which deletes OVS bridges from patch OVS
  #interfaces
  def self.unmangle__bridge(provider, val)
    if val.length == 2
      val.delete('br-prv') if val.include?('br-prv')
      val.delete('br-floating') if val.include?('br-floating')
      val
    end
    val.select!{ |x| x != :absent }
    val.join()
  end

end

# vim: set ts=2 sw=2 et :
