require 'puppet/parameter/boolean'

Puppet::Type.newtype(:merge_yaml_settings) do

  desc 'Type to merge YAML configuration files'

  ensurable do
    defaultvalues
    defaultto :present
  end

  newparam(:name) do
    desc 'The name of this merge resource'
    isnamevar
  end

  newparam(:path) do
    desc 'Path to the target YAML file'
    defaultto do
      fail 'The target "path" should be provided!'
    end
    validate do |value|
      unless Puppet::Util.absolute_path? value
        fail "The target file path should be an absolute path to a YAML file! Got: #{value.inspect}"
      end
    end
  end

  newparam(:original_data) do
    desc 'Path or Hash containing the source settings. It will be used if there is no file created at "path"'
    validate do |value|
      break unless value
      break if value.is_a? Hash
      break if value.is_a? Array
      unless Puppet::Util.absolute_path? value
        fail "The original data should be either a data structure or an absolute path to a YAML file! Got: #{value.inspect}"
      end
    end
  end

  newparam(:override_data) do
    desc 'The override data structure or a path to the YAML file containing it.'
    validate do |value|
      break unless value
      break if value.is_a? Hash
      break if value.is_a? Array
      unless Puppet::Util.absolute_path? value
        fail "The override data should be either a data structure or an absolute path to a YAML file! Got: #{value.inspect}"
      end
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
end
