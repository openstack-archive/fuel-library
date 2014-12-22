require File.join(File.dirname(__FILE__), 'l23_stored_config_base')

class Puppet::Provider::L23_stored_config_centos6 < Puppet::Provider::L23_stored_config_base

  # @return [String] The path to network-script directory on redhat systems
  def self.script_directory
    "/etc/sysconfig/network-scripts"
  end

  NAME_MAPPINGS = {
    :method     => 'BOOTPROTO',
    :name       => 'DEVICE',
    :onboot     => 'ONBOOT',
    :mtu        => 'MTU',
    :vlan_id    => 'VLAN',
    :vlan_dev   => 'PHYSDEV',
    :vlan_mode  => 'VLAN_NAME_TYPE',
    :if_type    => 'TYPE'
  }

  # In the interface config files those fields should be written as boolean
  BOOLEAN_FIELDS = [
    :vlan_id,
    :hotplug,
    :onboot
  ]

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
    # Split up the file into lines
    lines = contents.split("\n")
    # Strip out all comments
    lines.map! { |line| line.sub(/#.*$/, '') }
    # Remove all blank lines
    lines.reject! { |line| line.match(/^\s*$/) }

    pair_regex = %r/^\s*(.+?)\s*=\s*(.*)\s*$/

    # Convert the data into key/value pairs
    pairs = lines.inject({}) do |hash, line|
      if (m = line.match pair_regex)
        key = m[1].strip
        val = m[2].strip
        hash[key] = val
      else
        raise Puppet::Error, %{#{filename} is malformed; "#{line}" did not match "#{pair_regex.to_s}"}
      end
      hash
    end

    props = self.munge(pairs)
    props.merge!({:family => :inet})

    debug("Resource hash for '#{props[:name]}' is '#{props}'")
    # The FileMapper mixin expects an array of providers, so we return the
    # single interface wrapped in an array
    [props]
  end


  def self.munge(pairs)
    props = {}

    # Unquote all values
    pairs.each_pair do |key, val|
      if (munged = val.to_s.gsub(/['"]/, ''))
        pairs[key] = munged
      end
    end

    # For each interface attribute that we recognize it, add the value to the
    # hash with our expected label
    NAME_MAPPINGS.merge({:nnname => 'NAME'}).each_pair do |type_name, redhat_name|
      if (val = pairs[redhat_name])
        # We've recognized a value that maps to an actual type property, delete
        # it from the pairs and copy it as an actual property
        pairs.delete(redhat_name)
        case type_name
          when /if_type/
            props[type_name] = val.downcase
          else
            props[type_name] = val
        end
      end
    end

    # use :name if no :device given
    if !props[:name] and props[:nnname]
      props[:name] = props[:nnname]
    end
    props.delete(:nnname)

    #!# # For all of the remaining values, blindly toss them into the options hash.
    #!# props[:options] = pairs if ! pairs.empty?

    BOOLEAN_FIELDS.each do |bool_property|
      if props[bool_property]
        props[bool_property] = ! (props[bool_property] =~ /yes/i).nil?
      end
    end



    #todo(sv): Calculate Method
    # if ! ['bootp', 'dhcp'].include? props[:method]
    #   props[:method] = 'static'
    # end

    props
  end

  def self.mangle__vlan_mode(val)
    if val.to_s.upcase == 'VLAN_PLUS_VID_NO_PAD'
      'vlan'
    else
      'eth'
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

    provider = providers[0]
    props    = {}

    # Map everything to a flat hash
    #props = (provider.options || {})

    NAME_MAPPINGS.keys.each do |type_name|
      val = provider.send(type_name)
      if val and val.to_s != 'absent'
        props[type_name] = val
      end
    end

    pairs = self.unmunge(props)

    content = pairs.inject('') do |str, (key, val)|
      str << %{#{key}=#{val}\n}
    end

    content
  end



  def self.unmunge(props)

    pairs = {}

    BOOLEAN_FIELDS.each do |bool_property|
      if props[bool_property]
        props[bool_property] = ((props[bool_property] == true) ? 'yes' : 'no')
      end
    end

    NAME_MAPPINGS.each_pair do |type_name, redhat_name|
      if (val = props[type_name])
        props.delete(type_name)
        case type_name
          when /if_type/
            pairs[redhat_name] = val.capitalize
          else
            pairs[redhat_name] = val
        end
      end
    end

    pairs.merge! props

    pairs.each_pair do |key, val|
      if val.is_a? String and val.match(/\s+/)
        pairs[key] = %{"#{val}"}
      end
    end

    pairs
  end

  def self.unmangle__vlan_mode(val)
    if val.to_s == 'vlan'
      'VLAN_PLUS_VID_NO_PAD'
    else
      nil
    end
  end

end