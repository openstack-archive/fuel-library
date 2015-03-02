require File.join(File.dirname(__FILE__), 'l23_stored_config_base')

class Puppet::Provider::L23_stored_config_ubuntu < Puppet::Provider::L23_stored_config_base

  # @return [String] The path to network-script directory on redhat systems
  def self.script_directory
    '/etc/network/interfaces.d'
  end

  def self.property_mappings
    {
      :if_type        => 'if_type',       # pseudo field, not found in config, but calculated
      :if_provider    => 'if_provider',   # pseudo field, not found in config, but calculated
      :method         => 'method',
      :name           => 'iface',
      :onboot         => 'auto',
      :mtu            => 'mtu',
      :bridge_ports   => 'bridge_ports',  # ports, members of bridge, fake property
      :bridge_stp     => 'bridge_stp',
      :vlan_dev       => 'vlan-raw-device',
      :ipaddr         => 'address',
  #   :netmask        => 'netmask',
      :gateway        => 'gateway',
      :gateway_metric => 'metric',     # todo: rename to 'metric'
  #   :dhcp_hostname  => 'hostname'
      :bond_master    => 'bond-master',
      :bond_slaves    => 'bond-slaves',
      :bond_mode      => 'bond-mode',
      :bond_miimon    => 'bond-miimon',
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
      :if_type,
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
    hash['if_provider'] = 'none'
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
          when /(auto|allow-ovs)/
              hash[$1] = true
              hash['if_provider'] = $1  # temporary store additional data for self.check_if_provider
              if ! hash.has_key?('iface')
                # setup iface name if it not given in iface directive
                mm = val.split(/\s+/)
                hash['iface'] = mm[0]
              end
          when /iface/
              mm = val.split(/\s+/)
              hash['iface'] = mm[0]
              hash['method'] = mm[2]
              # if hash['iface'] =~ /^br.*/i
              #   # todo(sv): Make more powerful methodology for recognizind Bridges.
              #   hash['if_type'] = :bridge
              # end
          when /bridge-ports/
              hash['if_type'] = :bridge
              hash[key] = val
          when /bond-(slaves|mode)/
              hash['if_type'] = :bond
              hash[key] = val
          else
              hash[key] = val
        end
      else
        raise Puppet::Error, %{#{filename} is malformed; "#{line}" did not match "#{pair_regex.to_s}"}
      end
      hash
    end
    # set mostly low-priority interface name if not given in config file
    hash['iface'] ||= dirty_iface_name

    props = self.mangle_properties(hash)
    props.merge!({:family => :inet})

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

    #!# # For all of the remaining values, blindly toss them into the options hash.
    #!# props[:options] = pairs if ! pairs.empty?

    boolean_properties.each do |bool_property|
      if props[bool_property]
        props[bool_property] = ! (props[bool_property] =~ /^\s*(yes|on)\s*$/i).nil?
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

    # Add onboot interfaces
    if provider.onboot
      content << "#{property_mappings[:onboot]} #{provider.name}"
    end

    # Add iface header
    content << "iface #{provider.name} inet #{provider.method}"

    # Map everything to a flat hash
    #props = (provider.options || {})
    props    = {}

    property_mappings.keys.select{|v| ! properties_fake.include?(v)}.each do |type_name|
      #binding.pry
      #debug("ZZZZZZZ: #{property_mappings}")
      val = provider.send(type_name)
      if val and val.to_s != 'absent'
        props[type_name] = val
      end
    end

    debug("format_file('#{filename}')::properties: #{props.inspect}")
    pairs = self.unmangle_properties(props)

    pairs.each_pair do |key, val|
      content << "#{key} #{val}" if ! val.nil?
    end

    debug("format_file('#{filename}')::content: #{content.inspect}")
    content << ''
    content.join("\n")
  end


  def self.unmangle_properties(props)
    pairs = {}

    boolean_properties.each do |bool_property|
      if ! props[bool_property].nil?
        props[bool_property] = ((props[bool_property].to_s.to_sym == :true)  ?  'yes'  :  'no')
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

    #pairs.merge! props

    # pairs.each_pair do |key, val|
    #   if val.is_a? String and val.match(/\s+/)
    #     debug("==[#{key.to_sym}]==[\"#{val}\"]==")
    #     pairs[key.to_sym] = "\"#{val}\""
    #   end
    # end

    pairs
  end

  def self.unmangle__ipaddr(val)
    (val.to_s.downcase == 'dhcp')  ?  nil  :  val
  end

  def self.unmangle__if_type(val)
    # in Debian family interface config file don't contains declaration of interface type
    nil
  end

  def self.unmangle__gateway_metric(val)
    (val.to_i == 0  ?  :absent  :  val.to_i)
  end

  def self.unmangle__bridge_ports(val)
    if val.size < 1 or [:absent, :undef].include? Array(val)[0].to_sym
      nil
    else
      val.sort.join(' ')
    end
  end

  def self.unmangle__bond_master(val)
    if [:none, :absent, :undef].include? val.to_sym
      nil
    else
      val
    end
  end

  def self.unmangle__bond_slaves(val)
    if val.size < 1 or [:absent, :undef].include? Array(val)[0].to_sym
      nil
    else
      val.sort.join(' ')
    end
  end

end
# vim: set ts=2 sw=2 et :