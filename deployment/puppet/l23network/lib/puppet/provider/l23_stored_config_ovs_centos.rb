require File.join(File.dirname(__FILE__), '..','..','puppet/provider/l23_stored_config_centos')

class Puppet::Provider::L23_stored_config_ovs_centos < Puppet::Provider::L23_stored_config_centos

  def self.property_mappings
    rv = super
    rv.merge!({
      :devicetype     => 'DEVICETYPE',
      :bridge         => 'OVS_BRIDGE',
      :lnx_bridge     => 'BRIDGE',
      :bond_slaves    => 'BOND_IFACES',
      :bonding_opts   => 'OVS_OPTIONS',
      :bond_mode      => 'bond_mode',
      :bond_miimon    => 'other_config:bond-miimon-interval',
      :bond_lacp      => 'lacp',
      :bond_lacp_rate => 'other_config:lacp-time',
      :bond_updelay   => 'bond_updelay',
      :bond_downdelay => 'bond_downdelay',
    })
    #delete non-OVS params
    [:bond_ad_select, :bond_xmit_hash_policy, :bond_master].each { |p| rv.delete(p) }
    return rv
  end

  def self.properties_fake
    rv = super
    rv.push(:devicetype)
    rv.push(:lnx_bridge)
    return rv
  end

  def self.get_catalog
    return unless @all_providers
    first_provider = @all_providers.first
    return unless first_provider
    class << first_provider
      attr_reader :resource
    end
    first_provider_resource = first_provider.resource
    first_provider_resource.catalog
  end

  def self.resource_in_catalog(type,title)
    catalog = get_catalog
    return unless catalog
    catalog.resources.find do |res|
      res.type == type.to_sym and res.name == title
    end
  end

  def self.provider_of(title)
    # This function is finding out the provider of bridge
    found_resource = resource_in_catalog :l23_stored_config, title
    return unless found_resource
    found_resource.provider.class.name
  end

  def self.format_patch_bridges(props)
    bridges = props[:bridge]
    raise  Puppet::Error, %{Patch #{props[:name]} has more than 2 bridges: #{bridges}. Patch can connect *ONLY* 2 bridges!} if bridges.size >2
    lnx_bridge = []
    ovs_bridge = []
    bridges.each do |bridge|
      bridge_provider = provider_of(bridge)
      if bridge_provider.to_s =~ /lnx_centos/
        lnx_bridge << bridge
      elsif bridge_provider.to_s =~ /ovs_centos/
        ovs_bridge << bridge
      else
        raise  Puppet::Error, %{Patch #{props[:name]}: the bridge #{bridge} provider #{bridge_provider} is not supported!}
      end
    end
    if lnx_bridge.size > ovs_bridge.size
      provider_problem = lnx_bridge
    elsif ovs_bridge.size > lnx_bridge.size
      provider_problem = ovs_bridge
    end
    raise Puppet::Error, %{Patch #{props[:name]} has the same provider bridges: #{provider_problem} !} if provider_problem
    props[:lnx_bridge] = lnx_bridge
    props[:bridge] = ovs_bridge
    props
  end

  def self.format_bond_opts(props)
    bond_options = []
    bond_properties = property_mappings.select { |k, v|  k.to_s =~ %r{bond_.*} and !([:bond_slaves].include?(k)) }
    bond_properties.each do |param, transform |
      if props.has_key?(param)
        bond_options << "#{transform}=#{props[param]}"
        props.delete(param)
      end
    end
    props[:bonding_opts]  = "\"#{bond_options.join(' ')}\""
    props
  end

  def self.parse_patch_bridges(hash)
    hash['OVS_BRIDGE'] = [hash['OVS_BRIDGE'], hash['BRIDGE']].join(' ')
    hash.delete('BRIDGE')
    hash
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
    val = "OVS#{val.to_s.capitalize}".to_sym
    val = 'OVSIntPort' if val.to_s == 'OVSVport'
    val
  end

  def self.mangle__if_type(val)
    val = val.gsub('OVS', '').downcase.to_sym
    val = :vport if val.to_s == 'intport'
    val
  end

  def self.unmangle__bond_slaves(provider, val)
    "\"#{val.join(' ')}\""
  end

  def self.mangle__bond_slaves(val)
    val.split(' ')
  end

  def self.unmangle__lnx_bridge(provider, val)
    val.join()
  end

  def self.unmangle__bridge(provider, val)
    val.join()
  end

  def self.mangle__bridge(val)
    val.split(' ')
  end



end

# vim: set ts=2 sw=2 et :
