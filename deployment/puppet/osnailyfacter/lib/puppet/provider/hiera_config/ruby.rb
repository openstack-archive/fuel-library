require 'yaml'

Puppet::Type.type(:hiera_config).provide(:ruby) do
  desc 'Manage Hiera configuration file'

  attr_accessor :resource
  attr_accessor :property_hash

  mk_resource_methods

  # the path to the Hiera config file, the resource name
  def config_file
    name
  end

  # path to the metadata yaml file form the resource
  def metadata_yaml_file
    resource[:metadata_yaml_file]
  end

  # the name of the plugins dir from the resource
  def plugins_dir
    resource[:plugins_dir]
  end

  # path to the Hiera data dir from the resource
  def data_dir
    resource[:data_dir]
  end

  # join basic and override directories to form the path to the override files directory
  # @return [String]
  def plugins_dir_path
    File.join data_dir.to_s, plugins_dir.to_s
  end

  # Add to the end of each override file
  # Commonly used to stop plugins contaminating globals
  # @return [String]
  def override_suffix
    resource[:override_suffix].to_s
  end

  # remove all memoization
  def reset
    @enabled_plugin_entries = nil
    @directory_plugin_entries = nil
    @reported_plugin_entries = nil
  end

  # try to get the list of plugin entries from the metadata file
  # returns nil if there is no metadata file
  # @return [Array, NilClass]
  def enabled_plugin_entries
    return @enabled_plugin_entries if @enabled_plugin_entries
    @enabled_plugin_entries = []
    data = read_metadata_yaml_file
    return @enabled_plugin_entries unless data.is_a? Hash
    return @enabled_plugin_entries unless data['plugins'].is_a? Array
    data['plugins'].each do |plugin|
      next unless plugin['name']
      @enabled_plugin_entries << File.join(plugins_dir, plugin['name'].to_s) + override_suffix
    end
    @enabled_plugin_entries.sort!
    debug "Found enabled plugin elements in: '#{metadata_yaml_file}': #{@enabled_plugin_entries.inspect}"
    @enabled_plugin_entries
  end

  # scan for the override directory and get all the data entries found there
  # sorts entries alphabetically
  # @return [Array]
  def directory_plugin_entries
    return @directory_plugin_entries if @directory_plugin_entries
    @directory_plugin_entries = []
    dir_entries(plugins_dir_path).each do |file|
      next unless file.end_with? '.yaml'
      file = file.gsub /\.yaml$/, ''
      @directory_plugin_entries << File.join(plugins_dir, file) + override_suffix
    end
    @directory_plugin_entries.sort!
    debug "Found directory plugin elements: #{@directory_plugin_entries.inspect}"
    @directory_plugin_entries
  end

  # try to find additional entries in the metadata
  # returns nil if there is no metadata file
  # @return [Array, NilClass]
  def reported_plugin_entries
    return @reported_plugin_entries if @reported_plugin_entries
    @reported_plugin_entries = []
    data = read_metadata_yaml_file
    return @reported_plugin_entries unless data.is_a? Hash
    return @reported_plugin_entries unless data['plugins'].is_a? Array
    data['plugins'].each do |plugin|
      next unless plugin['name']
      plugins_elements = plugin.fetch 'hiera', []
      section_root_elements = data.fetch(plugin['name'], {}).fetch('hiera', [])
      section_metadata_elements = data.fetch(plugin['name'], {}).fetch('metadata', []).fetch('hiera', [])

      plugins_elements = [plugins_elements] if plugins_elements.is_a? String
      section_root_elements = [section_root_elements] if section_root_elements.is_a? String
      section_metadata_elements = [section_metadata_elements] if section_metadata_elements.is_a? String

      listed_elements = []
      listed_elements += plugins_elements if plugins_elements.is_a? Array
      listed_elements += section_root_elements if section_root_elements.is_a? Array
      listed_elements += section_metadata_elements if section_metadata_elements.is_a? Array

      listed_elements.each do |element|
        @reported_plugin_entries << File.join(plugins_dir, element.to_s) + override_suffix
      end
    end
    @reported_plugin_entries.sort!
    debug "Found listed plugin elements in '#{resource[:metadata_yaml_file]}': #{@reported_plugin_entries.inspect}"
    @reported_plugin_entries
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

  # retrieve only bottom hierarchy part from the configuration structure
  # @return [Array]
  def get_bottom_hierarchy(data)
    hierarchy = data[:hierarchy] || []
    bottom_hierarchy = []
    plugins_block = false
    bottom_block = false
    hierarchy.each do |element|
      if element.start_with? plugins_dir
        plugins_block = true unless bottom_block or plugins_block
      else
        bottom_block = true if plugins_block and not bottom_block
      end
      bottom_hierarchy << element if bottom_block
    end
    bottom_hierarchy
  end

  # retrieve only top hierarchy part from the configuration structure
  # @return [Array]
  def get_top_hierarchy(data)
    hierarchy = data[:hierarchy] || []
    top_hierarchy = []
    hierarchy.each do |element|
      break if element.start_with? plugins_dir
      top_hierarchy << element
    end
    top_hierarchy
  end

  # retrieve only override hierarchy part from the configuration structure
  # @return [Array]
  def get_plugins_hierarchy(data)
    hierarchy = data[:hierarchy] || []
    hierarchy.select do |element|
      element.start_with? plugins_dir
    end
  end

  # join both hierarchy parts to form the hierarchy structure
  # @return [Array]
  def generate_hierarchy
    hierarchy = []
    hierarchy += hierarchy_top if hierarchy_top.is_a? Array
    hierarchy += hierarchy_plugins if hierarchy_plugins.is_a? Array
    hierarchy += hierarchy_bottom if hierarchy_bottom.is_a? Array
    hierarchy
  end

  # try to get plugin entries from the metadata file
  # or from the directory scan entries
  # and don't touch entries if they are manually provided
  def generate_plugins_entries
    return if resource[:hierarchy_plugins].is_a? Array and resource[:hierarchy_plugins].any?
    entries = []
    entries += directory_plugin_entries
    entries += enabled_plugin_entries
    entries += reported_plugin_entries
    entries << 'plugins_placeholder' unless entries.any?
    entries.uniq!
    resource[:hierarchy_plugins] = entries
  end

  # load parameters from the configuration structure read from the config file
  # @return [Hash]
  def load_configuration
    return if property_hash.is_a? Hash and property_hash.any?
    generate_plugins_entries
    data = read_configuration
    self.property_hash = {}
    property_hash[:logger] = data[:logger]
    property_hash[:backends] = data[:backends]
    property_hash[:data_dir] = data.fetch(:yaml, {})[:datadir]
    property_hash[:hierarchy_top] = get_top_hierarchy data
    property_hash[:hierarchy_plugins] = get_plugins_hierarchy data
    property_hash[:hierarchy_bottom] = get_bottom_hierarchy data
    property_hash[:merge_behavior] = data[:merge_behavior]
    property_hash[:additions] = {}

    data.each do |key, value|
      next if managed_keys.include? key
      property_hash[:additions].store key, value
    end

    debug "Loaded configuration: #{property_hash.inspect}"
    property_hash
  end

  # directly managed config file top level keys
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
      data = yaml_load_file metadata_yaml_file
      return unless data.is_a? Hash
      data
    rescue => exception
      debug "Error parsing metadata file: '#{metadata_yaml_file}': #{exception.message}"
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
    generate_plugins_entries
    property_hash[:logger] = resource[:logger]
    property_hash[:backends] = resource[:backends]
    property_hash[:data_dir] = resource[:data_dir]
    property_hash[:merge_behavior] = resource[:merge_behavior]
    property_hash[:hierarchy_top] = resource[:hierarchy_top]
    property_hash[:hierarchy_plugins] = resource[:hierarchy_plugins]
    property_hash[:hierarchy_bottom] = resource[:hierarchy_bottom]
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
