require 'yaml'

Puppet::Type.type(:hiera_config).provide(:ruby) do
  desc 'Manage Hiera configuration file'

  attr_accessor :property_hash
  attr_accessor :resource

  def logger
    load_configuration
    property_hash[:logger]
  end

  def logger=(value)
    property_hash[:logger] = value
  end

  def merge_behavior
    property_hash[:merge_behavior]
  end

  def merge_behavior=(value)
    property_hash[:merge_behavior] = value
  end

  def hierarchy
    load_configuration
    property_hash[:hierarchy]
  end

  def hierarchy=(value)
    property_hash[:hierarchy] = value
  end

  def hierarchy_override
    load_configuration
    property_hash[:hierarchy_override]
  end

  def hierarchy_override=(value)
    property_hash[:hierarchy_override] = value
  end

  def data_dir
    load_configuration
    property_hash[:data_dir]
  end

  def data_dir=(value)
    property_hash[:data_dir] = value
  end

  def config_file
    resource[:name]
  end

  #####

  # try to get the list of plugin entries from the metadata file
  # returns nil if there is no metadata file
  # @return [Array, NilClass]
  def metadata_plugin_entries
    return @override_metadata_elements if @override_metadata_elements
    data = read_metadata_yaml_file
    return unless data.is_a? Hash
    @override_metadata_elements = []
    data.keys.each do |key|
      key_value = data.fetch(key, {})
      next unless key_value.is_a? Hash
      metadata_value = key_value.fetch('metadata', {})
      next unless metadata_value.is_a? Hash
      plugin_id = metadata_value.fetch('plugin_id', nil)
      @override_metadata_elements << File.join(resource[:override_dir].to_s, key) if plugin_id
    end
    @override_metadata_elements.sort!
    debug "Found plugins hierarchy elements in '#{resource[:metadata_yaml_file]}': #{@override_metadata_elements.inspect}"
    @override_metadata_elements
  end

  # join basic and override directories to form the path to the override files directory
  # @return [String]
  def override_dir_path
    return @override_dir_path if @override_dir_path
    path = File.join resource[:data_dir].to_s, resource[:override_dir].to_s
    return nil unless File.directory? path
    @override_dir_path = path
  end

  # scan for the override directory and get all the data entries found there
  # sorts entries alphabeticly
  # @return [Array]
  def override_directory_entries
    return @override_directory_elements if @override_directory_elements
    @override_directory_elements = []
    return @override_directory_elements unless override_dir_path
    dir_entries(override_dir_path).each do |file|
      next unless file.end_with? '.yaml'
      file = file.gsub /\.yaml$/, ''
      @override_directory_elements << File.join(resource[:override_dir].to_s, file)
    end
    @override_directory_elements.sort!
    debug "Found override hierarchy elements: #{@override_directory_elements.inspect}"
    @override_directory_elements
  end

  # read the directory entries
  # @param dir [String]
  # @return [Array]
  def dir_entries(dir)
    return [] unless File.directory? dir
    Dir.entries dir
  end

  # load this file as a YAML structure
  # @param file [String]
  # @return [Object]
  def yaml_load_file(file)
    return unless File.exists? file
    YAML.load_file file
  end

  # retrieve only basic hierarhy part from the confugaration structure
  # @return [Array]
  def get_basic_hierarchy(data)
    hierarchy = data[:hierarchy] || []
    hierarchy.reverse.reject do |element|
      element.start_with? resource[:override_dir]
    end
  end

  # retrieve only override hierarhy part from the confugaration structure
  # @return [Array]
  def get_override_hierarchy(data)
    hierarchy = data[:hierarchy] || []
    hierarchy.reverse.select do |element|
      element.start_with? resource[:override_dir]
    end
  end

  # join both hierarhy parts to form the hierarhy structure
  # @return [Array]
  def generate_hierarhy
    hierarchy = []
    hierarchy += property_hash[:hierarchy] if property_hash[:hierarchy].is_a? Array
    hierarchy += property_hash[:hierarchy_override] if property_hash[:hierarchy_override].is_a? Array
    hierarchy.reverse
  end

  # try to get plugin entries from the metadata file
  # or from the directory scan entries
  # and don't touch entries if they are manually provided
  def generate_override_entries
    return if resource[:hierarchy_override].is_a? Array and resource[:hierarchy_override].any?
    entries = metadata_plugin_entries
    entries = override_directory_entries unless entries
    resource[:hierarchy_override] = entries
  end

  # load parameters from the configuration structure read from the coinfig file
  # @return [Hash]
  def load_configuration
    return if property_hash.is_a? Hash and property_hash.any?
    generate_override_entries
    data = read_configuration
    self.property_hash = {}
    property_hash[:logger] = data[:logger]
    property_hash[:data_dir] = data.fetch(:yaml, {})[:datadir]
    property_hash[:hierarchy] = get_basic_hierarchy data
    property_hash[:hierarchy_override] = get_override_hierarchy data
    property_hash[:merge_behavior] = data[:merge_behavior]

    debug "Loaded configuration: #{property_hash.inspect}"
    property_hash
  end

  # generate configuration data structure from the parameters
  # @return [Hash]
  def generate_configuration
    config = {}
    backends = ['yaml']

    config[:logger] = property_hash[:logger]
    config[:yaml] = {:datadir => property_hash[:data_dir]}
    config[:hierarchy] = generate_hierarhy
    config[:backends] = backends
    config[:merge_behavior] = property_hash[:merge_behavior]

    debug "Generated configuration: #{config.inspect}"
    config
  end

  # readt the hiera configuratio file
  # @return [Hash]
  def read_configuration
    begin
      data = yaml_load_file config_file
      return {} unless data.is_a? Hash
      data
    rescue => exception
      debug "Error parsing config file: '#{config_file}': #{exception.message}"
      {}
    end
  end

  # read the metadata yaml file and return either data
  # or nil if the file was not read or is not correct
  # @return [Hash, NilClass]
  def read_metadata_yaml_file
    begin
      data = yaml_load_file resource[:metadata_yaml_file]
      return unless data.is_a? Hash
      data
    rescue => exception
      debug "Error parsing metadata file: '#{resource[:metadata_yaml_file]}': #{exception.message}"
      nil
    end
  end

  # write the generated data to the hiera config
  # @param [Hash] data
  def write_configuration(data)
    File.open(config_file, 'w') do |file|
      file.puts data.to_yaml
    end
  end

  def flush
    debug 'Call: flush'
    configuration = read_configuration.merge generate_configuration
    debug "Writing configuration: #{configuration.inspect}"
    write_configuration configuration
  end

end
