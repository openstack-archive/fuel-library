require File.join(File.dirname(__FILE__), 'l23_stored_config_base')

class Puppet::Provider::L23_stored_config_centos6 < Puppet::Provider::L23_stored_config_base

  # @return [String] The path to network-script directory on redhat systems
  def self.script_directory
    '/etc/sysconfig/network-scripts'
  end

  def self.property_mappings
    {
      :method      => 'BOOTPROTO',
      :ipaddr      => 'IPADDR',
      :name        => 'DEVICE',
      :onboot      => 'ONBOOT',
      :mtu         => 'MTU',
      :vlan_id     => 'VLAN',
      :vlan_dev    => 'PHYSDEV',
      :vlan_mode   => 'VLAN_NAME_TYPE',
      :if_type     => 'TYPE',
      :bridge      => 'BRIDGE',
      :prefix      => 'PREFIX',
      :gateway     => 'GATEWAY',
      :bond_master => 'MASTER',
      :slave       => 'SLAVE',
      :bond_mode   => 'mode',
      :bond_miimon => 'miimon',
      :bonding_opts => 'BONDING_OPTS',
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
    if hash.has_key?('IPADDR')
      hash['IPADDR'] = "#{hash['IPADDR']}/#{hash['PREFIX']}"
      hash.delete('PREFIX')
    end

    if hash.has_key?('BONDING_OPTS')
      bonding_opts_line = hash['BONDING_OPTS'].scan(/"([^"]*)"/).to_s.split
      bonding_opts_line.each do | bond_opt |
        if (bom = bond_opt.match(pair_regex))
          hash[bom[1].strip] = bom[2].strip
        else
          raise Puppet::Error, %{#{filename} is malformed; "#{line}" did not match "#{pair_regex.to_s}"}
        end
      end
      hash.delete('BONDING_OPTS')
    end

    props = self.mangle_properties(hash)
    props.merge!({:family => :inet})

    debug("parse_file('#{filename}'): #{props.inspect}")
    [props]

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


  def self.mangle__if_type(val)
    val.to_s.downcase.intern
  end

  def self.mangle__method(val)
    if [:manual, :static].include? val
      :none
    end
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
      if val and val.to_s != 'absent'
        props[type_name] = val
      end
    end

    if props.has_key?(:ipaddr)
      props[:prefix] = props[:ipaddr].split('/')[1]
      props[:ipaddr] = props[:ipaddr].split('/')[0]
    end
    if props.has_key?(:bond_master)
       props[:slave] = 'yes'
    end


    debug("format_file('#{filename}')::properties: #{props.inspect}")
    pairs = self.unmangle_properties(props)

    if pairs.has_key?('mode')
      pairs['BONDING_OPTS'] = "\"mode=#{pairs['mode']} miimon=#{pairs['miimon']}\""
      pairs.delete('mode')
      pairs.delete('miimon')
    end

    if pairs['TYPE'] == :OVSBridge
      pairs['DEVICETYPE'] = 'ovs'
    end

    pairs.each_pair do |key, val|
      content << "#{key}=#{val}" if ! val.nil?
    end

    debug("format_file('#{filename}')::content: #{content.inspect}")
    content << ''
    content.join("\n")
  end

    pairs.each_pair do |key, val|
      content << "#{key}=#{val}" if ! val.nil?
    end

    debug("format_file('#{filename}')::content: #{content.inspect}")
    content << ''
    content.join("\n")
  end

  def self.unmangle_properties(props)
    pairs = {}

    boolean_properties.each do |bool_property|
      if ! props[bool_property].nil?
        props[bool_property] = (props[bool_property].to_s.to_sym == :true || props[bool_property].integer?) ? 'yes' : 'no'
      end
    end

    property_mappings.each_pair do |type_name, in_config_name|
      if (val = props[type_name])
        props.delete(type_name)
        mangle_method_name="unmangle__#{type_name}"
        if self.respond_to?(mangle_method_name)
          rv = self.send(mangle_method_name, val)
        else
          rv = val
        end
        pairs[in_config_name] = rv if ! [nil, :absent].include? rv
      end
    end

    pairs
  end

  def self.unmangle__if_type(val)
    val.to_s.capitalize.intern
  end

  def self.unmangle__method(val)
    if [:manual, :static].include? val
      :none
    end
  end


end
# vim: set ts=2 sw=2 et :
