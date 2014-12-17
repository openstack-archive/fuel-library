require File.join(File.dirname(__FILE__), 'l23_stored_config_base')

class Puppet::Provider::L23_stored_config_ubuntu < Puppet::Provider::L23_stored_config_base

  # @return [String] The path to network-script directory on redhat systems
  def self.script_directory
    '/etc/network/interfaces.d'
  end

  NAME_MAPPINGS = {
    :method     => 'method',  # fake papping
    :name       => 'iface',
    :onboot     => 'auto',
    :mtu        => 'mtu',
  }

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
    hash['type'] = :Ethernet
    dirty_iface_name = nil
    if (m = filename.match(%r/ifcfg-(\S+)$/))
      # save iface name from file name. One will be used if iface name not defined inside config.
      dirty_iface_name = m[1].strip
    end

    # Convert the data into key/value pairs
    pair_regex = %r/^\s*(.+?)\s+(.*)\s*$/
    lines.each do |line|
      if (m = line.match(pair_regex))
        key = m[1].strip
        val = m[2].strip
        case key
          # Ubuntu has non-linear config format. Some options should be calculated evristically
          when /auto/
              hash['auto'] = true
              if ! hash.has_key?('iface')
                # setup iface name if it not given in iface directive
                mm = val.split(/\s+/)
                hash['iface'] = mm[0]
              end
          when /iface/
              mm = val.split(/\s+/)
              hash['iface'] = mm[0]
              hash['method'] = mm[2]
              if hash['iface'] =~ /^br.*/i
                # todo(sv): Make more powerful methodology for recognizind Bridges.
                hash['type'] = :Bridge
              end
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
    [props]
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
    NAME_MAPPINGS.each_pair do |type_name, in_config_name|
      if (val = pairs[in_config_name])
        # We've recognized a value that maps to an actual type property, delete
        # it from the pairs and copy it as an actual property
        pairs.delete(in_config_name)
        mangle_method_name="mangle__#{type_name}"
        if self.class.respond_to?(mangle_method_name)
          props[type_name] = self.class.send(mangle_method_name, val)
        else
          props[type_name] = val
        end

      end
    end

    #!# # For all of the remaining values, blindly toss them into the options hash.
    #!# props[:options] = pairs if ! pairs.empty?

    # [:onboot, :hotplug].each do |bool_property|
    #   if props[bool_property]
    #     props[bool_property] = ! (props[bool_property] =~ /yes/i).nil?
    #   end
    # end

    props
  end

  def self.mangle__method(val)
    val.to_sym
  end

  def self.mangle__type(val)
    val.downcase.to_sym
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
      content << "auto #{provider.name}"
    end

    # Add iface header
    content << "iface #{provider.name} inet #{provider.method}"

    # Map everything to a flat hash
    #props = (provider.options || {})
    props    = {}

    NAME_MAPPINGS.keys.select{|v| ! [:onboot, :name, :family, :method, :type].include?(v)}.each do |type_name|
      val = provider.send(type_name)
      if val and val.to_s != 'absent'
        props[type_name] = val
      end
    end

    pairs = self.unmangle_properties(props)

    pairs.each_pair do |key, val|
      content << "#{key} #{val}" if ! val.nil?
    end
    content << ''

    content.join("\n")
  end


  def self.unmangle_properties(props)
    pairs = {}

    NAME_MAPPINGS.each_pair do |type_name, in_config_name|
      if (val = props[type_name])
        props.delete(type_name)
        mangle_method_name="unmangle__#{type_name}"
        if self.class.respond_to?(mangle_method_name)
          pairs[in_config_name] = self.class.send(mangle_method_name, val)
        else
          pairs[in_config_name] = val
        end
      end
    end

    #pairs.merge! props

    pairs.each_pair do |key, val|
      if val.is_a? String and val.match(/\s+/)
        pairs[key.to_sym] = "#{val}"
      end
    end

    pairs
  end

  def self.unmangle__onboot(val)
    ((val == true) ? 'yes' : 'no')
  end

  def self.unmangle__hotplug(val)
    ((val == true) ? 'yes' : 'no')
  end

  def self.unmangle__type(val)
    val.capitalize
  end


end