require File.join(File.dirname(__FILE__), '..','..','puppet/provider/l23_stored_config_centos')

class Puppet::Provider::L23_stored_config_ovs_centos < Puppet::Provider::L23_stored_config_centos

  def self.property_mappings
    rv = super
    rv.merge!({
      :devicetype   => 'DEVICETYPE',
      :bridge       => 'OVS_BRIDGE',
      :bond_slaves  => 'BOND_IFACES',
      :bonding_opts => 'OVS_OPTIONS',
      :bond_mode    => 'bond_mode',
      :bond_lacp    => 'lacp',
      :bond_miimon  => 'other_config:bond-miimon-interval',
    })
    return rv
  end

  def self.properties_fake
    rv = super
    rv.push(:devicetype)
    rv.push(:bond_ad_select)
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
    bond_options = []
    [:bond_mode, :bond_miimon, :bond_lacp].each do |param|
      if props.has_key?(param)
        bond_options << "#{property_mappings[param]}=#{props[param]}"
        props.delete(param)
      end
    end
    props[:bonding_opts]  = "\"#{bond_options.join(' ')}\""
    props
  end

  def self.parse_bond_opts(hash)
    pair_regex = %r/^\s*(.+?)\s*=\s*(.*)\s*$/
    if hash.has_key?('OVS_OPTIONS')
      bonding_opts_line = hash['OVS_OPTIONS'].gsub('"', '').split(' ')
      bonding_opts_line.each do | bond_opt |
        if (bom = bond_opt.match(pair_regex))
          hash[bom[1].strip] = bom[2].strip
        else
          raise Puppet::Error, %{#{filename} is malformed; "#{line}" did not match "#{pair_regex.to_s}"}
        end
      end
    hash.delete('OVS_OPTIONS')
    end
    hash
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
