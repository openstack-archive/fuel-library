require 'yaml'
require_relative '../../yaml_deep_merge'

Puppet::Type.type(:merge_yaml_settings).provide(:ruby) do
  desc 'Support for merging yaml configuration files.'

  attr_reader :resource

  # Create a new target YAML file
  def create
    debug 'Call: create'
    data = merged_data
    return if data.empty?
    write_to_file(resource[:path], data)
  end

  # Convert data structure to a YAML file contents
  # @param [Hash] data
  # @return [String]
  def serialize_data(data)
    data.to_yaml.gsub('x5c', '\\')
  end

  # A hash of options for the deep merge module
  # @return [Hash]
  def deep_merge_options
    {
        :preserve_unmergeables => resource[:preserve_unmergeables],
        :knockout_prefix => resource[:knockout_prefix],
        :overwrite_arrays => resource[:overwrite_arrays],
        :sort_merged_arrays => resource[:sort_merged_arrays],
        :unpack_arrays => resource[:unpack_arrays],
        :merge_hash_arrays => resource[:merge_hash_arrays],
        :extend_existing_arrays => resource[:extend_existing_arrays],
        :merge_debug => resource[:merge_debug],
    }
  end

  # Enable additional debug messages
  # @return [true,false]
  def merge_debug
    deep_merge_options[:merge_debug]
  end

  # Remove the target yaml file
  def destroy
    debug 'Call: destroy'
    File.unlink resource[:path] if File.exists? resource[:path]
  end

  # Check if the sample file contains the correct merged structure
  def exists?
    debug 'Call: exists?'
    return false unless target_yaml_file?
    debug "Exists original: #{original_data.inspect}" if merge_debug
    debug "Exists merged: #{merged_data.inspect}" if merge_debug
    result = original_data == merged_data
    debug "Return: #{result}"
    result
  end

  # Produce the merged data structure by merging
  # the original data data with the override data.
  # @return [Hash]
  def merged_data
    debug 'Call: merged_data'
    debug "Merge original: #{original_data.inspect}" if merge_debug
    debug "Merge override: #{override_data.inspect}" if merge_debug
    original_data_clone = Marshal.load Marshal.dump original_data
    YamlDeepMerge.deep_merge! override_data, original_data_clone, deep_merge_options
    debug "Result: #{original_data_clone.inspect}" if merge_debug
    original_data_clone
  end

  # Write the merged data to the specified file name
  # @param [String] file_name
  # @param [Hash] data
  def write_to_file(file_name, data)
    debug "Writing content to the file: '#{file_name}'"
    content = serialize_data data
    begin
      File.open(file_name, 'w') { |f| f.puts content }
    rescue => exception
      fail "The file: '#{file_name}' cannot be written! #{exception}"
    end
  end

  # Read the contents of the YAML file
  # @param [String] file_name
  def read_from_file(file_name)
    debug "Reading content from the file: '#{file_name}'"
    begin
      YAML.load_file(file_name)
    rescue => exception
      warn "The file: '#{file_name}' cannot be read! #{exception}"
      nil
    end
  end

  # The original portion of the YAML file.
  # If the target file if present it will be loaded.
  # If there is no target file, the original_data will be loaded as a file
  # or as a data structure.
  # @return [Hash,Array]
  def original_data
    return @original_data if @original_data
    if target_yaml_file?
      @original_data = read_from_file resource[:path]
      return @original_data if @original_data
    end
    if original_data_file?
      @original_data = read_from_file resource[:original_data]
      return @original_data if @original_data
    end
    unless resource[:original_data].is_a? Hash or resource[:original_data].is_a? Array
      fail "The original_data should be either a path to the YAML file or the data structure! Got: #{resource[:original_data]}"
    end
    @original_data = resource[:original_data]
  end

  # The override portion of the YAML file.
  # If the override_data are provided as a path to a file
  # the file will be loaded.
  # @return [Hash,Array]
  def override_data
    return @override_data if @override_data
    if override_data_file?
      @override_data = read_from_file resource[:override_data]
      return @override_data if @override_data
    end
    unless resource[:override_data].is_a? Hash or resource[:override_data].is_a? Array
      fail "The override_data should be either a path to the YAML file or the data structure! Got: #{resource[:override_data]}"
    end
    @override_data = resource[:override_data]
  end

  # Check if the target YAML file exists
  # @return [true,false]
  def target_yaml_file?
    return false unless resource[:path].is_a? String
    return false unless File.absolute_path resource[:path]
    File.file? resource[:path]
  end

  # Check if original_data are provided as a file
  # and the file is present
  # @return [true,false]
  def original_data_file?
    return false unless resource[:original_data].is_a? String
    return false unless File.absolute_path resource[:original_data]
    File.file? resource[:original_data]
  end

  # Check if the override_data are provided as a file
  # and the file is present
  # @return [true,false]
  def override_data_file?
    return false unless resource[:override_data].is_a? String
    return false unless File.absolute_path resource[:override_data]
    File.file? resource[:override_data]
  end

end
