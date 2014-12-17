require File.join(File.dirname(__FILE__), 'l23_stored_config_base')

class Puppet::Provider::L23_stored_config_ubuntu < Puppet::Provider::L23_stored_config_base

  # @return [String] The path to network-script directory on redhat systems
  SCRIPT_DIRECTORY = '/etc/network/interfaces.d'

  NAME_MAPPINGS = {
    :method     => 'method',  # fake papping
    :name       => 'iface',
    :onboot     => 'auto',
    :mtu        => 'mtu',
  }

  # Map provider instances to files based on their name
  #
  # @return [String] The path of the file for the given interface resource
  #
  # @example
  #   prov = RedhatProvider.new(:name => 'eth1')
  #   prov.select_file # => '/etc/sysconfig/network-scripts/ifcfg-eth1'
  #
  def select_file
    "#{SCRIPT_DIRECTORY}/ifcfg-#{name}"
  end  # Scan all files in the networking directory for interfaces
  #
  # @param script_dir [String] The path to the networking scripts, defaults to
  #   {#SCRIPT_DIRECTORY}
  #
  # @return [Array<String>] All network-script config files on this machine.
  #
  # @example
  #   RedhatProvider.target_files
  #   # => ['/etc/sysconfig/network-scripts/ifcfg-eth0', '/etc/sysconfig/network-scripts/ifcfg-eth1']
  def self.target_files(script_dir = SCRIPT_DIRECTORY)
    entries = Dir.entries(script_dir).select {|entry| entry.match SCRIPT_REGEX}
    entries.map {|entry| File.join(SCRIPT_DIRECTORY, entry)}
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
    # Split up the file into lines
    lines = contents.split("\n")
    # Strip out all comments
    lines.map! { |line| line.sub(/#.*$/, '') }
    # Remove all blank lines
    lines.reject! { |line| line.match(/^\s*$/) }

    pair_regex = %r/^\s*(.+?)\s+(.*)\s*$/

    # Convert the data into key/value pairs
    hash = {}
    hash[:onboot] = false
    lines.each do |line|
      if (m = line.match(pair_regex))
        key = m[1].strip
        val = m[2].strip
        case key
            when /auto/
                hash['auto'] = true
            when /iface/
                mm = val.split(/\s+/)
                hash['iface'] = mm[0]
                hash['method'] = mm[2]
                if hash['iface'] =~ /^br.*/i
                  hash['type'] = :Bridge
                else
                  hash['type'] = :Ethernet
                end
            else
                hash[key] = val
        end
      else
        raise Puppet::Error, %{#{filename} is malformed; "#{line}" did not match "#{pair_regex.to_s}"}
      end
      hash
    end

    props = self.munge(hash)
    props.merge!({:family => :inet})

    # The FileMapper mixin expects an array of providers, so we return the
    # single interface wrapped in an array
    [props]
  end


  def self.munge(pairs)
    props = {}

    # Unquote all values
    pairs.each_pair do |key, val|
      next if ! (val.is_a? String or val.is_a? Symbol)
      if (munged = val.gsub(/['"]/, ''))
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
        props[type_name] = val
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

    pairs = self.unmunge(props)

    content << pairs.inject('') do |str, (key, val)|
      str << %{#{key} #{val}\n}
    end

    content.join("\n")
  end



  def self.unmunge(props)

    pairs = {}

    [:onboot, :hotplug].each do |bool_property|
      if props[bool_property]
        props[bool_property] = ((props[bool_property] == true) ? 'yes' : 'no')
      end
    end

    NAME_MAPPINGS.each_pair do |type_name, in_config_name|
      if (val = props[type_name])
        props.delete(type_name)
        pairs[in_config_name] = val
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

end