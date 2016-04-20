require 'yaml'

Puppet::Type.type(:hiera_config).provide(:ruby) do
  desc 'Manage Hiera configuration file'

  attr_accessor :property_hash
  attr_accessor :resource

  # Getters and Setters

  def logger
    property_hash[:logger]
  end

  def logger=(value)
    property_hash[:logger] = value
  end

  def backends
    property_hash[:backends]
  end

  def backends=(value)
    property_hash[:backends] = value
  end

  def merge_behavior
    property_hash[:merge_behavior]
  end

  def merge_behavior=(value)
    property_hash[:merge_behavior] = value
  end

  def hierarchy
    property_hash[:hierarchy]
  end

  def hierarchy=(value)
    property_hash[:hierarchy] = value
  end

  def hierarchy_override
    property_hash[:hierarchy_override]
  end

  def hierarchy_override=(value)
    property_hash[:hierarchy_override] = value
  end

  def data_dir
    property_hash[:data_dir]
  end

  def data_dir=(value)
    property_hash[:data_dir] = value
  end

  def additions
    property_hash[:additions]
  end

  def additions=(value)
    property_hash[:additions] = value
  end

  #####

  # join basic and override directories to form the path to the override files directory
  # @return [String]
  def override_dir_path
    File.join resource[:data_dir].to_s, override_dir_name
  end

  # base name of the override directory
  # @return [String]
  def override_dir_name
    resource[:override_dir].to_s
  end

  # the path to the Hiera config file
  # @return [String]
  def config_file
    resource[:path].to_s
  end

  # remove all memoization
  def reset
    @override_metadata_elements = nil
    @override_directory_elements = nil
  end

  # try to get the list of plugin entries from the metadata file
  # returns nil if there is no metadata file
  # @return [Array, NilClass]
  def metadata_plugin_entries
    return @override_metadata_elements if @override_metadata_elements
    data = read_metadata_yaml_file
    return unless data.is_a? Hash
    return unless data['plugins'].is_a? Array
    @override_metadata_elements = []
    data['plugins'].each do |plugin|
      next unless plugin['name']
      @override_metadata_elements << File.join(override_dir_name, plugin['name'].to_s)
    end
    @override_metadata_elements.sort!
    debug "Found plugins hierarchy elements in '#{resource[:metadata_yaml_file]}': #{@override_metadata_elements.inspect}"
    @override_metadata_elements
  end

  # scan for the override directory and get all the data entries found there
  # sorts entries alphabetically
  # @return [Array]
  def override_directory_entries
    return @override_directory_elements if @override_directory_elements
    @override_directory_elements = []
    dir_entries(override_dir_path).each do |file|
      next unless file.end_with? '.yaml'
      file = file.gsub /\.yaml$/, ''
      @override_directory_elements << File.join(override_dir_name, file)
    end
    @override_directory_elements.sort!
    debug "Found override hierarchy elements: #{@override_directory_elements.inspect}"
    @override_directory_elements
  end

  # read the directory entries
  # @param dir [String]
  # @return [Array]
  def dir_entries(dir)
    return [] unless dir and File.directory? dir
    Dir.entries dir
  end

  # load this file as a YAML structure
  # @param file [String]
  # @return [Object]
  def yaml_load_file(file)
    return unless file and File.exists? file
    YAML.load_file file
  end

  # retrieve only basic hierarchy part from the configuration structure
  # @return [Array]
  def get_basic_hierarchy(data)
    hierarchy = data[:hierarchy] || []
    hierarchy.reject do |element|
      element.start_with? override_dir_name
    end
  end

  # retrieve only override hierarchy part from the configuration structure
  # @return [Array]
  def get_override_hierarchy(data)
    hierarchy = data[:hierarchy] || []
    hierarchy.select do |element|
      element.start_with? override_dir_name
    end
  end

  # join both hierarchy parts to form the hierarchy structure
  # @return [Array]
  def generate_hierarchy
    hierarchy = []
    hierarchy += property_hash[:hierarchy_override] if property_hash[:hierarchy_override].is_a? Array
    hierarchy += property_hash[:hierarchy] if property_hash[:hierarchy].is_a? Array
    hierarchy
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

  # load parameters from the configuration structure read from the config file
  # @return [Hash]
  def load_configuration
    return if property_hash.is_a? Hash and property_hash.any?
    generate_override_entries
    data = read_configuration
    self.property_hash = {}
    property_hash[:logger] = data[:logger]
    property_hash[:backends] = data[:backends]
    property_hash[:data_dir] = data.fetch(:yaml, {})[:datadir]
    property_hash[:hierarchy] = get_basic_hierarchy data
    property_hash[:hierarchy_override] = get_override_hierarchy data
    property_hash[:merge_behavior] = data[:merge_behavior]
    property_hash[:additions] = {}

    data.each do |key, value|
      next if managed_keys.include? key
      property_hash[:additions].store key, value
    end

    debug "Loaded configuration: #{property_hash.inspect}"
    property_hash
  end

  # managed config file keys
  # @return [Array]
  def managed_keys
    resource.managed_keys
  end

  # generate configuration data structure from the parameters
  # @return [Hash]
  def generate_configuration
    config = {}
    config[:logger] = logger
    config[:backends] = backends
    config[:yaml] = {:datadir => data_dir}
    config[:hierarchy] = generate_hierarchy
    config[:merge_behavior] = merge_behavior
    config.merge! additions if additions.is_a? Hash
    debug "Generated configuration: #{config.inspect}"
    config
  end

  # read the hiera configuration file
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

  # remove the Hiera configuration file
  def remove_configuration
    File.delete config_file if configuration_present?
  end

  # check if the Hiera configuration file exists
  # @return [TrueClass,FalseClass]
  def configuration_present?
    File.exists? config_file
  end

  #####

  def exists?
    debug 'Call: exists?'
    load_configuration
    configuration_present?
  end

  def destroy
    debug 'Call: destroy'
    remove_configuration
    self.property_hash = {}
  end

  def create
    debug 'Call: create'
    self.property_hash = {}
    generate_override_entries
    property_hash[:logger] = resource[:logger]
    property_hash[:backends] = resource[:backends]
    property_hash[:data_dir] = resource[:data_dir]
    property_hash[:merge_behavior] = resource[:merge_behavior]
    property_hash[:hierarchy] = resource[:hierarchy]
    property_hash[:hierarchy_override] = resource[:hierarchy_override]
    property_hash[:additions] = resource[:additions]
  end

  def flush
    debug 'Call: flush'
    return unless property_hash.is_a? Hash and property_hash.any?
    configuration = generate_configuration
    debug "Writing configuration: #{configuration.inspect}"
    write_configuration configuration
  end

end
