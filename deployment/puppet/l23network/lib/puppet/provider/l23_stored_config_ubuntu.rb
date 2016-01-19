require 'puppetx/l23_utils'
require 'puppetx/l23_ethtool_name_commands_mapping'
require File.join(File.dirname(__FILE__), 'l23_stored_config_base')

class Puppet::Provider::L23_stored_config_ubuntu < Puppet::Provider::L23_stored_config_base

  # @return [String] The path to network-script directory on redhat systems
  def self.script_directory
    '/etc/network/interfaces.d'
  end

  def self.target_files(script_dir = nil)
    provider = self.name
    debug("Collecting target files for #{provider}")
    entries = super
    regoc_regex = %r{ovs_type}
    if provider =~ /ovs_/
      entries.select! { |entry| !open(entry).grep(regoc_regex).empty? }
    elsif provider =~ /lnx_/
      entries.select! { |entry| open(entry).grep(regoc_regex).empty? }
    end
    entries
  end

  def self.property_mappings
    {
      :if_type               => 'if_type',       # pseudo field, not found in config, but calculated
      :if_provider           => 'if_provider',   # pseudo field, not found in config, but calculated
      :method                => 'method',
      :name                  => 'iface',
      :onboot                => 'auto',
      :mtu                   => 'mtu',
      :bridge_ports          => 'bridge_ports',  # ports, members of bridge, fake property
      :bridge_stp            => 'bridge_stp',
      :vlan_dev              => 'vlan-raw-device',
      :ipaddr                => 'address',
  #   :netmask               => 'netmask',
      :gateway               => 'gateway',
      :gateway_metric        => 'metric',     # todo: rename to 'metric'
  #   :dhcp_hostname         => 'hostname'
      :bond_master           => 'bond-master',
      :bond_slaves           => 'bond-slaves',
      :bond_mode             => 'bond-mode',
      :bond_miimon           => 'bond-miimon',
      :bond_use_carrier      => 'bond-use-carrier',
      :bond_lacp             => '', # unused for lnx
      :bond_lacp_rate        => 'bond-lacp-rate',
      :bond_updelay          => 'bond-updelay',
      :bond_downdelay        => 'bond-downdelay',
      :bond_ad_select        => 'bond-ad-select',
      :bond_xmit_hash_policy => 'bond-xmit-hash-policy'
    }
  end
  def property_mappings
    self.class.property_mappings
  end

  # Some resources can be defined as repeatable strings in the config file
  # these properties should be fetched by RE-scanning and converted to array
  def self.collected_properties
    {
      :routes  => {
          # post-up ip route add (default/10.20.30.0/24) via 1.2.3.4 [metric NN]
          :detect_re    => /(post-)?up\s+ip\s+r([oute]+)?\s+add\s+(default|\d+\.\d+\.\d+\.\d+\/\d+)\s+via\s+(\d+\.\d+\.\d+\.\d+)(\s+metric\s+\d+)?/,
          :detect_shift => 3,
      },
      :ethtool => {
          # post-up ethtool -K eth2 property [on|off]
          :detect_re    => /(post-)?up\s+ethtool\s+(-\w+)\s+([\w\-]+)\s+(\w+)\s+(\w+)/,
          :detect_shift => 2,
      },
      :ipaddr_aliases => {
          # ip addr add 192.168.1.43/24 dev $IFACE
          :detect_re    => /(post-)?up\s+ip\s+a([dr]+)?\s+add\s+(\d+\.\d+\.\d+\.\d+\/\d+)\s+dev\s+([\w\-]+)/,
          :detect_shift => 3,
      },
      :delay_while_up  => {
          # post-up sleep 10
          :detect_re    => /(post-)?up\s+sleep\s+(\d+)/,
          :detect_shift => 2,
      },
      :jacks  => {
          # pre-up ip link add p_33470efd-0 type veth peer name p_33470efd-1
          :detect_re    => /pre-up\s+ip\s+link\s+add\s+([\w\-]+)\s+mtu\s+(\d+)\s+type\s+veth\s+peer\s+name\s+([\w\-]+)+mtu\s+(\d+)/,
          :detect_shift => 1,
      },
    }
  end
  def collected_properties
    self.class.collected_properties
  end

  # Some properties can be defined as repeatable key=value string part in the
  # one option in config file these properties should be fetched by RE-scanning
  #
  def self.oneline_properties
    { }
  end
  def oneline_properties
    self.class.oneline_properties
  end

  # In the interface config files those fields should be written as boolean
  def self.boolean_properties
    [
      :onboot,
      :hotplug,
      :bridge_stp
    ]
  end
  def boolean_properties
    self.class.boolean_properties
  end

  def self.properties_fake
    [
      :onboot,
      :name,
      :family,
      :method,
      :if_provider
    ]
  end
  def properties_fake
    self.class.properties_fake
  end

  # This is a hook method that will be called by PuppetX::Filemapper
  #
  # @param [String] filename The path of the interfaces file being parsed
  # @param [String] contents The contents of the given file
  #
  # @return [Array<Hash<Symbol, String>>] A single element array containing
  #   the key/value pairs of properties parsed from the file.
  #
  # @example
  #   RedhatProvider.parse_file('/etc/sysconfig/network-scripts/ifcfg-eth0', #<String:0xdeadbeef>)
  #   # => [
  #   #   {
  #   #     :name      => 'eth0',
  #   #     :ipaddress => '169.254.0.1',
  #   #     :netmask   => '255.255.0.0',
  #   #   },
  #   # ]

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
    hash['auto'] = false
    hash['if_provider'] = 'lnx'
    hash['if_type'] = :ethernet
    dirty_iface_name = nil
    if (m = filename.match(%r/ifcfg-(\S+)$/))
      # save iface name from file name. One will be used if iface name not defined inside config.
      dirty_iface_name = m[1].strip
    end

    # Convert the data into key/value pairs
    pair_regex = %r/^\s*([\w+\-]+)\s+(.*)\s*$/
    lines.each do |line|
      if (m = line.match(pair_regex))
        key = m[1].strip
        val = m[2].strip
        case key
          # Ubuntu has non-linear config format. Some options should be calculated evristically
          when /auto/
              ooper = $1
              if ! hash.has_key?('iface')
                # setup iface name if it not given in iface directive
                mm = val.split(/\s+/)
                hash['iface'] = mm[0]
              end
              hash['auto'] = true
              hash['if_provider'] ||= "lnx"
          when /allow-(\S+)/
              if $1 == 'ovs'
                hash['if_provider'] = "ovs"
                hash['if_type'] = "bridge"
              end
              if ! hash.has_key?('iface')
                # setup iface name if it not given in iface directive
                mm = val.split(/\s+/)
                hash['iface'] = mm[0]
              end
          when /(ovs_\S)/
              hash['if_provider'] = "ovs" if ! (hash['if_provider'] =~ /ovs/)
              hash[key] = val
              if key == 'ovs_bonds'
                hash['if_type'] = 'bond'
              end
          when /iface/
              mm = val.split(/\s+/)
              hash['iface'] = mm[0]
              hash['method'] = mm[2]
              # if hash['iface'] =~ /^br.*/i
              #   # todo(sv): Make more powerful methodology for recognizind Bridges.
              #   hash['if_type'] = :bridge
              # end
          when /bridge[-_]ports/
              hash['if_type'] = :bridge
              hash[key] = val
          when /bond[-_](slaves|mode)/
              hash['if_type'] = :bond
              hash[key] = val
          else
              hash[key] = val
        end
        if val =~ /\s+type\s+veth\s+/
              hash['if_type'] = :patch
        end
      else
        raise Puppet::Error, %{#{filename} is malformed; "#{line}" did not match "#{pair_regex.to_s}"}
      end
      hash
    end
    # set mostly low-priority interface name if not given in config file
    hash['iface'] ||= dirty_iface_name

    props = self.mangle_properties(hash)

    # scan for one-line properties set
    props.reject{|x| !oneline_properties.keys.include?(x)}.each do |key, line|
      _k = Regexp.quote(oneline_properties[key][:field])
      line =~ /#{_k}=(\S+)/
      val = $1
      props[key] = val
    end

    props.merge!({:family => :inet})
    # collect properties, defined as repeatable strings
    collected=[]
    lines.each do |line|
      rv = []
      collected_properties.each_pair do |r_name, rule|
        if rg=line.match(rule[:detect_re])
          props[r_name] ||= []
          props[r_name] << rg[rule[:detect_shift]..-1]
          collected << r_name if !collected.include? r_name
          next
        end
      end
    end
    # mangle collected properties if ones has specific method for it
    collected.each do |prop_name|
      mangle_method_name="mangle__#{prop_name}"
      rv = (self.respond_to?(mangle_method_name)  ?  self.send(mangle_method_name, props[prop_name])  :  props[prop_name])
      props[prop_name] = rv if ! ['', 'absent'].include? rv.to_s.downcase
    end

    props.merge!({:provider => self.name})

    # The FileMapper mixin expects an array of providers, so we return the
    # single interface wrapped in an array
    rv = (self.check_if_provider(props)  ?  [props]  :  [])
    debug("parse_file('#{filename}'): #{props.inspect}")
    rv
  end

  def self.check_if_provider(if_data)
    raise Puppet::Error, "self.check_if_provider(if_data) Should be implemented in more specific class."
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
        mangle_method_name="mangle__#{type_name}"
        if self.respond_to?(mangle_method_name)
          rv = self.send(mangle_method_name, val)
        else
          rv = val
        end
        props[type_name] = rv if ! [nil, :absent].include? rv
      end
    end

    #!# # For all of the remaining values, blindly toss them into the options hash.
    #!# props[:options] = pairs if ! pairs.empty?

    boolean_properties.each do |bool_property|
      if props[bool_property]
        props[bool_property] = ! (props[bool_property].to_s =~ /^\s*(yes|on|true)\s*$/i).nil?
      else
        props[bool_property] = :absent
      end
    end

    props
  end

  def self.mangle__method(val)
    val.to_sym
  end

  def self.mangle__if_type(val)
    val.downcase.to_sym
  end

  def self.mangle__gateway_metric(val)
    (val.to_i == 0  ?  :absent  :  val.to_i)
  end

  def self.mangle__bridge_ports(val)
    val.split(/[\s,]+/).sort
  end

  def self.mangle__bond_slaves(val)
    val.split(/[\s,]+/).sort
  end

  def self.mangle__routes(data)
    # incoming data is list of 3-element lists:
    # [network, gateway, metric]
    # metric is optional
    rv = {}
    data.each do |d|
      if d[2]
        metric = d[2].split(/\s+/)[-1].to_i
      else
        metric = 0
      end
      name = L23network.get_route_resource_name(d[0], metric)
      rv[name] = {
        'destination' => d[0],
        'gateway' =>     d[1]
      }
      rv[name][:metric] = metric if metric > 0
    end
    return rv
  end

  def self.mangle__ipaddr_aliases(data)
    # incoming data is list of 3-element lists:
    # [network, gateway, metric]
    # metric is optional
    rv = []
    data.each do |d|
      rv << d[0]
    end
    return rv.sort
  end

  def self.mangle__ethtool(data)
    # incoming data is list of 3-element lists:
    # [key, interface, abbrv, value]
    rv = {}
    data.each do |record|
      # use .reject bellow for compatibilities with ruby 1.8
      section = L23network.ethtool_name_commands_mapping.reject{|k,v| v['__section_key_set__']!=record[0]}
      next if section.empty?
      section_name = section.keys[0]
      key_fullname = section[section_name].reject{|k, v| v!=record[2]}.to_a
      next if key_fullname.empty?
      key_fullname = key_fullname[0][0]
      next if key_fullname.to_s == ''
      rv[section_name] ||= {}
      rv[section_name][key_fullname] = (record[3]=='on')
    end
    return rv
  end

  def self.mangle__delay_while_up(data)
    # incoming data is sleep delay
    # if multiple sleeps present we should sum are delays
    rv = 0
    data.each do |record|
      rv += record[0].to_i
    end
    return rv
  end

  def self.mangle__jacks(data)
    [data[0][0], data[0][1]]
  end

  ###
  # Hash to file

  def self.iface_file_header(provider)
    raise Puppet::Error, "self.iface_file_header(provider) Should be implemented in more specific class."
  end

  def self.format_file(filename, providers)
    if providers.length == 0
      return ""
    elsif providers.length > 1
      raise Puppet::DevError, "Unable to support multiple interfaces [#{providers.map(&:name).join(',')}] in a single file #{filename}"
    end

    provider = providers[0]
    content, props = iface_file_header(provider)

    property_mappings.reject{|k,v| (properties_fake.include?(k) or v.empty?)}.keys.each do |type_name|
      next if props.has_key? type_name
      val = provider.send(type_name)
      next if ( val.is_a?(Array) and val.reject{ |x| x.to_s == 'absent' }.empty? )
      if val and val.to_s != 'absent'
        props[type_name] = val
      end
    end

    debug("format_file('#{filename}')::properties: #{props.inspect}")
    pairs = self.unmangle_properties(provider, props)



    pairs.each_pair do |key, val|
      content << "#{key} #{val}" if ! val.nil?
    end

    #add to content unmangled collected-properties
    collected_properties.keys.each do |type_name|
      data = provider.send(type_name)
      if ! ['', 'absent'].include? data.to_s
        mangle_method_name="unmangle__#{type_name}"
        if self.respond_to?(mangle_method_name)
          rv = self.send(mangle_method_name, provider, data)
        end
        content += rv if ! (rv.nil? or rv.empty?)
      end
    end


    debug("format_file('#{filename}')::content: #{content.inspect}")
    content << ''
    content.join("\n")
  end


  def self.unmangle_properties(provider, props)
    pairs = {}

    boolean_properties.each do |bool_property|
      if ! props[bool_property].nil?
        props[bool_property] = ((props[bool_property].to_s.to_sym == :true)  ?  'yes'  :  'no')
      end
    end

    #Unmangling values for ordinary properties.
    property_mappings.each_pair do |type_name, in_config_name|
      if (val = props[type_name])
        props.delete(type_name)
        mangle_method_name="unmangle__#{type_name}"
        if self.respond_to?(mangle_method_name)
          rv = self.send(mangle_method_name, provider, val)
        else
          rv = val
        end
        # assembly one-line option set
        if oneline_properties.has_key? type_name
          _key = oneline_properties[type_name][:store_to]
          pairs[_key] ||= ''
          pairs[_key] += "#{oneline_properties[type_name][:field]}=#{rv} "
        else
          pairs[in_config_name] = rv if ! [nil, :absent].include? rv
        end
      end
    end

    pairs
  end

  def self.unmangle__ipaddr(provider, val)
    (val.to_s.downcase == 'dhcp')  ?  nil  :  val
  end

  def self.unmangle__if_type(provider, val)
    # in Debian family interface config file don't contains declaration of interface type
    nil
  end

  def self.unmangle__gateway_metric(provider, val)
    (val.to_i == 0  ?  :absent  :  val.to_i)
  end

  def self.unmangle__bridge_ports(provider, val)
    if val.size < 1 or [:absent, :undef].include? Array(val)[0].to_sym
      nil
    else
      val.sort.join(' ')
    end
  end

  def self.unmangle__bond_master(provider, val)
    if [:none, :absent, :undef].include? val.to_sym
      nil
    else
      val
    end
  end

  def self.unmangle__bond_slaves(provider, val)
    if val.size < 1 or [:absent, :undef].include? Array(val)[0].to_sym
      nil
    else
      val.sort.join(' ')
    end
  end

  def self.unmangle__routes(provider, data)
    # should generate set of lines:
    # "post-up ip route add % via % | true"
    return [] if ['', 'absent'].include? data.to_s
    rv = []
    data.each_pair do |name, rou|
      mmm = (rou['metric'].nil?  ?  ''  :  "metric #{rou['metric']} ")
      rv << "post-up ip route add #{rou['destination']} via #{rou['gateway']} #{mmm} | true # #{name}"
    end
    rv
  end

  def self.unmangle__ipaddr_aliases(provider, data)
    # should generate set of lines:
    # "post-up ip addr add 192.168.1.43/24 dev $IFACE| true"
    return [] if ['', 'absent'].include? data.to_s
    rv = []
    data.each do |cidr|
      next if ['', 'absent'].include? cidr.to_s
      rv << "post-up ip addr add #{cidr} dev #{provider.name} | true "
    end
    rv
  end

  def self.unmangle__delay_while_up(provider, data)
    # should generate one line:
    # "post-up sleep NN"
    return [] if ['', 'absent'].include? data.to_s
    ["post-up sleep #{data[0]}"]
  end

  def self.unmangle__ethtool(provider, data)
    # should generate set of lines:
    # "post-up ethtool -K %interface_name% property [on|off]"
    return [] if ['', 'absent'].include? data.to_s
    rv = []
    data.each do |section_name, rules|
      next if L23network.ethtool_name_commands_mapping[section_name].nil?
      section_key = L23network.ethtool_name_commands_mapping[section_name]['__section_key_set__']
      next if section_key.nil?
      rules.each do |k,v|
        next if L23network.ethtool_name_commands_mapping[section_name][k].nil?
        iface=provider.name
        val = (v==true  ?  'on'  :  'off')
        rv << "post-up ethtool #{section_key} #{iface} #{L23network.ethtool_name_commands_mapping[section_name][k]} #{val} | true  # #{k}"
      end
    end
    return rv
  end

  def self.unmangle__jacks(provider, data)
    rv = []
    pre_up = "pre-up ip link add #{data[0]} mtu 1500 type veth peer name #{data[1]} mtu 1500"
    pre_up = "pre-up ip link add #{data[0]} mtu #{provider.send(:mtu)} type veth peer name #{data[1]} mtu #{provider.send(:mtu)}" unless ['', 'absent'].include?(provider.send(:mtu).to_s)
    rv << pre_up
    rv << "post-up ip link set up dev #{data[1]}"
    rv << "post-down ip link del #{data[0]}"
  end

end
# vim: set ts=2 sw=2 et :
