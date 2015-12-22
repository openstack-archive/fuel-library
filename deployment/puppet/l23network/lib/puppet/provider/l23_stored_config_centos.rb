require 'puppetx/l23_ethtool_name_commands_mapping'
require File.join(File.dirname(__FILE__), 'l23_stored_config_base')

class Puppet::Provider::L23_stored_config_centos < Puppet::Provider::L23_stored_config_base

  # @return [String] The path to network-script directory on redhat systems
  def self.script_directory
    '/etc/sysconfig/network-scripts'
  end

  def self.target_files(script_dir = nil)
    provider = self.name.to_s
    debug("Collecting target files for #{provider}")
    entries = super
    regoc_regex = %r{TYPE=OVS}
    if provider =~ /ovs_/
      entries = entries.reject { |entry| open(entry).grep(regoc_regex).empty? }
    elsif provider =~ /lnx_/
      entries = entries.select { |entry| open(entry).grep(regoc_regex).empty? }
    end
    entries
  end

  def self.property_mappings
    {
      :method                => 'BOOTPROTO',
      :ipaddr                => 'IPADDR',
      :name                  => 'DEVICE',
      :onboot                => 'ONBOOT',
      :mtu                   => 'MTU',
      :vlan_id               => 'VLAN',
      :vlan_dev              => 'PHYSDEV',
      :vlan_mode             => 'VLAN_NAME_TYPE',
      :if_type               => 'TYPE',
      :bridge                => 'BRIDGE',
      :prefix                => 'PREFIX',
      :gateway               => 'GATEWAY',
      :gateway_metric        => 'METRIC',
      :bond_master           => 'MASTER',
      :slave                 => 'SLAVE',
      :bond_mode             => 'mode',
      :bond_miimon           => 'miimon',
      :bonding_opts          => 'BONDING_OPTS',
      :bond_lacp_rate        => 'lacp_rate',
      :bond_ad_select        => 'ad_select',
      :bond_xmit_hash_policy => 'xmit_hash_policy',
      :bond_updelay          => 'updelay',
      :bond_downdelay        => 'downdelay',
      :ethtool               => 'ETHTOOL_OPTS',
      :routes                => 'ROUTES',
      :jacks                 => 'JACKS',
    }
  end
  def property_mappings
    self.class.property_mappings
  end

  # In the interface config files those fields should be written as boolean
  def self.boolean_properties
    [
      :hotplug,
      :onboot,
      :vlan_id,
    ]
  end
  def boolean_properties
    self.class.boolean_properties
  end

  def self.properties_fake
    [
      :prefix,
      :vlan_mode,
      :vlan_dev,
      :slave,
      :bonding_opts,
      :delay_while_up,
    ]
  end
  def properties_fake
    self.class.properties_fake
  end

  def self.parse_file(filename, contents)
    # WARNING!!!
    # this implementation can parce only one interface per file file format

    # Split up the file into lines
    lines = contents.split("\n")
    # Strip out all comments
    lines.map! { |line| line.sub(/#.*$/, '') }
    # Remove all blank lines
    lines.reject! { |line| line.match(/^\s*$/) }

    # initialize hash as predictible values
    hash = {}
    dirty_iface_name = nil
    if (m = filename.match(%r/ifcfg-(\S+)$/))
      # save iface name from file name. One will be used if iface name not defined inside config.
      dirty_iface_name = m[1].strip
    end

    # Convert the data into key/value pairs
    pair_regex = %r/^\s*(.+?)\s*=\s*(.*)\s*$/

    lines.each do |line|
      if (m = line.match(pair_regex))
        key = m[1].strip
        val = m[2].strip
        hash[key] = val
      else
        raise Puppet::Error, %{#{filename} is malformed; "#{line}" did not match "#{pair_regex.to_s}"}
      end
      hash
    end

    route_filename = "#{self.script_directory}/route-#{dirty_iface_name}"
    if File.exist?(route_filename)
      route_file = open(route_filename, 'r')
      rv = {}
      while (line = route_file.gets)
        rv[line.split(' ')[0]] = line
      end
      route_file.close
      hash['ROUTES'] = rv
    end

    if hash.has_key?('IPADDR')
      hash['IPADDR'] = "#{hash['IPADDR']}/#{hash['PREFIX']}"
      hash.delete('PREFIX')
    end

    # reading preup file for patch if it exists
    if preup_content = self.read_file("#{self.script_directory}/pre-up-ifcfg-#{dirty_iface_name}") and !preup_content.empty?
      hash['JACKS'] = preup_content
      hash['TYPE'] = 'Patch'
    end

    hash.delete('DEVICETYPE') if hash['DEVICETYPE']
    hash['DEVICE'] = hash['NAME'] if (!hash['DEVICE'] and hash['NAME'])

    # Do extra actions if ovs2lnx patch cord
    hash = self.parse_patch_bridges(hash) if ( hash.has_key?('BRIDGE') and hash.has_key?('OVS_BRIDGE') )

    hash = self.parse_bond_opts(hash) if ( hash.has_key?('TYPE') and hash['TYPE'] =~ %r{Bond} )

    props = self.mangle_properties(hash)
    props.merge!({:name => dirty_iface_name}) unless props.has_key?(:name)
    props.merge!({:family => :inet})
    props.merge!({:provider => self.name})

    debug("parse_file('#{filename}'): #{props.inspect}")
    [props]
  end

  def self.check_if_provider(if_data)
    raise Puppet::Error, "self.check_if_provider(if_data) Should be implemented in more specific class."
  end

  def self.parse_patch_bridges(hash)
    # Do nothing, this is only needed for ovs provider
    hash
  end

  def self.parse_bond_opts(hash)
    if hash.has_key?('BONDING_OPTS')
      bonding_opts_line = hash['BONDING_OPTS'].gsub('"', '').split(' ')
      pair_regex = %r/^\s*(.+?)\s*=\s*(.*)\s*$/
      bonding_opts_line.each do | bond_opt |
        if (bom = bond_opt.match(pair_regex))
          hash[bom[1].strip] = bom[2].strip
        else
          raise Puppet::Error, %{#{filename} is malformed; "#{line}" did not match "#{pair_regex.to_s}"}
        end
      end
      hash.delete('BONDING_OPTS')
    end
    hash
  end

  def self.mangle_properties(pairs)
    props = {}

    # Unquote all values
    pairs.each_pair do |key, val|
      next if ! (val.is_a? String or val.is_a? Symbol)
      if (munged = val.to_s.gsub(/['"]/, ''))
        pairs[key] = munged
      end
    end

    # For each interface attribute that we recognize it, add the value to the
    # hash with our expected label
    property_mappings.each_pair do |type_name, in_config_name|
      if (val = pairs[in_config_name])
        # We've recognized a value that maps to an actual type property, delete
        # it from the pairs and copy it as an actual property
        pairs.delete(in_config_name)
        mangle_method_name="mangle__#{type_name}"
        if self.respond_to?(mangle_method_name)
          rv = self.send(mangle_method_name, val)
        else
          rv = val
        end
        props[type_name] = rv if ! [nil, :absent].include? rv
      end
    end

    boolean_properties.each do |bool_property|
      if props[bool_property]
        props[bool_property] = ! (props[bool_property] =~ /^\s*(yes|on)\s*$/i).nil?
      else
        props[bool_property] = :absent
      end
    end

    props
  end

  def self.mangle__bridge(val)
    Array(val)
  end

  def self.mangle__if_type(val)
    val.to_s.downcase.to_sym
  end

  def self.mangle__method(val)
    val = 'manual' if val.to_s == 'none'
    val.to_s.downcase
  end

  def self.mangle__ethtool(val)
    rv = {}
    val.split(' ;').each do | section |
      section_config = section.split('  ')
      feature_params = {}
      section_name = ''
      L23network.ethtool_name_commands_mapping.each do |key, value |
           section_name = key if value==section_config[0].split(' ')[0]
           value.each { | k, v |  section_name = key if v==section_config[0].split(' ')[0] } if value.is_a?(Hash)
      end
      next if section_name == ''
      section_features = section_config.select {|k| k !=  section_config[0]}
      section_features.each do | feature |
         k,v =  feature.split(' ')
         tk = Hash[L23network.ethtool_name_commands_mapping[section_name].select { |key, value| value==k }]
         next if tk == ''
         feature_params[tk.keys.join()] = ((v=='on'  ?  true  :  false))
      end
      rv[section_name] = feature_params
    end
    rv
  end

  def self.mangle__routes(data)
    rv = {}
    data.each_pair do |k,v|
      gateway = v.match(/via ((?:[0-9]{1,3}\.){3}[0-9]{1,3}) /)[1]
      route_params = { 'destination' => k ,
                       'gateway'     => gateway
                     }
      if v.include? 'metric'
        metric = v.match(/metric (\d+)/)[1]
        route_params['metric'] = metric
      end
      name = L23network.get_route_resource_name(k, metric)
      rv[name] = route_params
    end
    return rv
  end

  def self.mangle__jacks(data)
   #data should be
   #ip link add p_3911f6cc-0 type veth peer name p_3911f6cc-1\nip link set up dev p_3911f6cc-1
   rv = []
   p "parse jacks #{data}"
   data.each_line do | line |
     jacks = line.scan(/ip\s+link\s+add\s+([\w\-]+)\s+type\s+veth\s+peer\s+name\s+([\w\-]+)/).flatten
     rv = jacks if !jacks.empty?
   end
   return rv
  end

  ###
  # Hash to file
  def self.format_file(filename, providers)
    if providers.length == 0
      return ""
    elsif providers.length > 1
      raise Puppet::DevError, "Unable to support multiple interfaces [#{providers.map(&:name).join(',')}] in a single file #{filename}"
    end

    content = []
    provider = providers[0]

    # Map everything to a flat hash
    props    = {}

    property_mappings.keys.select{|v| ! properties_fake.include?(v)}.each do |type_name|
      val = provider.send(type_name)
      next if ( val.is_a?(Array) and val.reject{ |x| x.to_s == 'absent' }.empty? )
      if val and val.to_s != 'absent'
        props[type_name] = val
      end
    end

    if props.has_key?(:ipaddr)
      props[:ipaddr], props[:prefix] = props[:ipaddr].to_s.split('/')
    end
    if props.has_key?(:bond_master)
       props[:slave] = 'yes'
    end

    # Do extra actions if ovs2lnx patch cord
    props = self.format_patch_bridges(props) if ( props[:if_type].to_s == 'vport' and props[:bridge].size > 1 )

    props = self.format_bond_opts(props) if props.has_key?(:bond_mode)

    debug("format_file('#{filename}')::properties: #{props.inspect}")
    pairs = self.unmangle_properties(provider, props)

    pairs['DEVICETYPE'] = 'ovs' if pairs['TYPE'].to_s =~ /OVS/

    if pairs['ROUTES']
      route_filename = "#{self.script_directory}/route-#{provider.name}"
      route_content = ""
      pairs['ROUTES'].each do |route|
        route_content << "#{route}\n"
      end
      self.write_file(route_filename, route_content)
      pairs.delete('ROUTES')
    end

    # Delete default gateway from global network file
    if pairs['GATEWAY']
      self.remove_line_from_file('/etc/sysconfig/network', /GATEWAY.*/)
    end

    #writing the pre-up file for patch
    if pairs['TYPE'].to_s == 'Patch' and pairs['JACKS']
      patch_pre_up_filename = "#{self.script_directory}/pre-up-ifcfg-#{provider.name}"
      self.write_file(patch_pre_up_filename, pairs['JACKS'])
      pairs.delete('TYPE')
      pairs.delete('JACKS')
    end

    pairs.each_pair do |key, val|
      content << "#{key}=#{val}" if ! val.nil?
    end

    debug("format_file('#{filename}')::content: #{content.inspect}")
    content << ''
    content.join("\n")
  end

  def self.read_file(file)
    content = ''
    content = File.read(file) if File.exist?(file)
    return content
  end

  def self.write_file(file, content)
    debug("write_file(): writing the file #{file} \nwith content:\n#{content}")
    begin
      File.open(file, 'w') do |writing_file|
        writing_file.write content.to_s
      end
    rescue
      raise Puppet::Error, "write_file(): file #{file} can not be written!"
    end
    File.chmod(0744, file)
  end

  def self.remove_line_from_file(file, remove)
    content = self.read_file(file).split("\n").reject { |line| remove === line }.join("\n") + "\n"
    self.write_file file, content
  end

  def self.format_patch_bridges(props)
    # Do nothing, this is only needed for ovs provider
    props
  end

  def self.format_bond_opts(props)
    bond_options = []
    bond_properties = property_mappings.select { |k, v|  k.to_s =~ %r{bond_.*} and !([:bond_master].include?(k)) }
    bond_properties.each do |param, transform |
      if props.has_key?(param)
        bond_options << "#{transform}=#{props[param]}"
        props.delete(param)
      end
    end
    props[:bonding_opts]  = "\"#{bond_options.join(' ')}\""
    props
  end

  def self.unmangle_properties(provider, props)
    pairs = {}
    boolean_properties.each do |bool_property|
      if ! props[bool_property].nil?
        props[bool_property] = (props[bool_property].to_s.downcase == 'true' || props[bool_property].integer?) ? 'yes' : 'no'
      end
    end

    property_mappings.each_pair do |type_name, in_config_name|
      if (val = props[type_name])
        props.delete(type_name)
        mangle_method_name="unmangle__#{type_name}"
        if self.respond_to?(mangle_method_name)
          rv = self.send(mangle_method_name, provider, val)
        else
          rv = val
        end
        pairs[in_config_name] = rv if ! ['', 'absent'].include? rv.to_s.downcase
      end
    end

    pairs
  end

  def self.unmangle__bridge(provider, val)
    val.join()
  end

  def self.unmangle__if_type(provider, val)
    val.to_s.capitalize
  end

  def self.unmangle__method(provider, val)
    (['manual', 'static'].include? val.to_s.downcase)  ?  'none'  :  val
  end

  def self.unmangle__ipaddr(provider, val)
    (val.to_s.downcase == 'dhcp')  ?  nil  :  val
  end

  def self.unmangle__ethtool(provider, val)
    rv = ''
    val.each do | section_name, features |
      next if L23network.ethtool_name_commands_mapping[section_name].nil?
      section_key = L23network.ethtool_name_commands_mapping[section_name]['__section_key_set__']
      next if section_key.nil?
      features.each do | feature, value |
        next if L23network.ethtool_name_commands_mapping[section_name][feature].nil?
        rv << " #{L23network.ethtool_name_commands_mapping[section_name][feature]} #{(value==true  ?  'on'  :  'off')} "
      end
      rv = "#{section_key} #{provider.name} #{rv};"
    end
    return "\"#{rv}\""
  end

  def self.unmangle__routes(provider, val)
    # should generate set of lines:
    # "10.109.55.0/24 via 192.168.1.54  dev br-storage"
    return [] if ['', 'absent'].include? val.to_s
    rv = []
    val.each_pair do |name, route|
      metric = (route['metric'].nil?  ?  ''  :  " metric #{route['metric']}")
      rv << "#{route['destination']} via #{route['gateway']}#{metric} dev #{provider.name}"
    end
    return rv
  end

  def self.unmangle__jacks(provider, data)
    rv = []
    rv << "ip link add #{data[0]} type veth peer name #{data[1]}"
    rv << "ip link set up dev #{data[1]}"
    rv.join("\n")
  end


end
# vim: set ts=2 sw=2 et :
