require 'yaml'
require 'json'
require 'puppet/parameter/boolean'
require 'puppet'
require 'digest/md5'
require_relative '../yaml_deep_merge'

Puppet::Type.newtype(:hash_merge) do
  ensurable do
    defaultvalues
    defaultto :present
  end

  newparam(:path) do
    desc 'The path to this file.'
    isnamevar
  end

  newparam(:hash_name) do
    desc 'Collect the fragments which are having this hash name.'
    isrequired
  end

  newparam(:type) do
    desc 'The type of serialization this hash is using.'
    newvalues :yaml, :json
    defaultto :yaml
  end

  newproperty(:data) do
    desc 'The collector for the merged fragments data'
    validate do |value|
      fail "The data should be a hash! Got: #{value.inspect}" unless value.is_a? Hash
    end

    def is_to_s(value)
      "(md5)#{Digest::MD5.hexdigest value.inspect}"
    end

    def should_to_s(value)
      "(md5)#{Digest::MD5.hexdigest value.inspect}"
    end
  end

  newparam(:knockout_prefix, :boolean => true, :parent => Puppet::Parameter::Boolean) do
    desc 'When merging hashes, remove elements from a hash if they are prefixed with "--".'
    defaultto true
  end

  newparam(:overwrite_arrays, :boolean => true, :parent => Puppet::Parameter::Boolean) do
    desc 'When merging hashes, overwrite array values instead of merging them.'
    defaultto false
  end

  newparam(:unpack_arrays) do
    desc 'Use this character as an array separator to unpack arrays which have been passed as a string.'
  end

  newparam(:merge_hash_arrays, :boolean => true, :parent => Puppet::Parameter::Boolean) do
    desc 'When merging hashes, merge hashes inside arrays too.'
    defaultto true
  end

  newparam(:extend_existing_arrays, :boolean => true, :parent => Puppet::Parameter::Boolean) do
    desc 'When merging hashes, add single values to an array value instead of overwriting it.'
    defaultto false
  end

  newparam(:preserve_unmergeables, :boolean => true, :parent => Puppet::Parameter::Boolean) do
    desc 'Set to true to skip any unmergeable elements from source.'
    defaultto false
  end

  newparam(:merge_debug, :boolean => true, :parent => Puppet::Parameter::Boolean) do
    desc 'Set to true to get console output of merge process for debugging.'
    defaultto false
  end

  newparam(:sort_merged_arrays, :boolean => true, :parent => Puppet::Parameter::Boolean) do
    desc 'Set to true to sort all arrays that are merged together.'
    defaultto false
  end

  # A hash of options for the deep merge module
  # @return [Hash]
  def deep_merge_options
    {
        :preserve_unmergeables => self[:preserve_unmergeables],
        :knockout_prefix => self[:knockout_prefix],
        :overwrite_arrays => self[:overwrite_arrays],
        :sort_merged_arrays => self[:sort_merged_arrays],
        :unpack_arrays => self[:unpack_arrays],
        :merge_hash_arrays => self[:merge_hash_arrays],
        :extend_existing_arrays => self[:extend_existing_arrays],
        :merge_debug => self[:merge_debug],
    }
  end

  def extract_data(fragment)
    fragment_data = fragment[:data]
    if not fragment_data and fragment[:content]
      if fragment[:type] == :yaml
        begin
          fragment_data = YAML.load(fragment[:content])
        rescue
          warn "Could not load the YAML content of the fragment: #{fragment[:name]}"
        end
      elsif fragment[:type] == :json
        begin
          fragment_data = JSON.parse(fragment[:content])
        rescue
          warn "Could not load the JSON content of the fragment: #{fragment[:name]}"
        end
      end
    end
    fragment_data
  end

  # Enable additional debug messages
  # @return [true,false]
  def merge_debug
    deep_merge_options[:merge_debug]
  end

  def fragments
    return [] unless self.respond_to? :catalog and self.catalog
    fragments = self.catalog.resources.select do |resource|
      resource.type == :hash_fragment and resource[:hash_name] == self[:hash_name]
    end
    fragments.sort_by! do |fragment|
      [fragment[:priority].to_i, fragment[:name]]
    end
    debug "Found fragments: #{fragments.map { |f| f.title }.join ', '}"
    fragments
  end

  def generate
    data = {}
    fragments.each do |fragment|
      fragment_data = extract_data(fragment)
      unless fragment_data
        warn "Fragment: #{fragment[:name]} has no data!" if merge_debug
        next
      end
      unless fragment_data.is_a? Hash
        warn "Fragment: #{fragment[:name]} data is not a hash! Got: #{fragment_data.inspect}}" if merge_debug
        next
      end
      debug "Merging the fragment: #{fragment[:name]}" if merge_debug
      YamlDeepMerge.deep_merge! fragment_data, data, deep_merge_options
    end
    self[:data] = data
    nil
  end

end
