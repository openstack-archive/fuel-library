Puppet::Type.newtype(:hiera_config) do
  desc 'Manage Hiera yaml configuration'

  ensurable

  newparam(:path) do
    desc 'The path to the Hiera config file.'
    isnamevar
  end

  newparam(:override_dir) do
    desc 'Look for override files in this directory.
         The directory should be inside the data directory and the path
         should be relative to the basic data directory path.'
    defaultto 'plugins'
  end

  newparam(:override_suffix) do
    desc 'Add suffix to all override files'
  end

  newparam(:metadata_yaml_file) do
    desc 'Look inside this YAML file for the list of enabled plugins.
          If this value is not defined or no file is present the list
          of plugins will be found from the content of the override directory
          directly.'
  end

  newproperty(:data_dir) do
    desc 'Basic directory with Hiera data elements'
    defaultto '/etc/hiera'
  end

  newproperty(:hierarchy, :array_matching => :all) do
    desc 'Basic hierarchy elements. This list of elements will be used at the
          bottom of the hierarchy before any overrides are applied.'
    defaultto []

    def is_to_s(value)
      value.inspect
    end

    def should_to_s(value)
      value.inspect
    end
  end

  newproperty(:hierarchy_override, :array_matching => :all) do
    desc 'Override hierarchy elements. These list will be automatically gathered
          either from the metadata file of from the override directory scanning.
          If you provide the list manually it will be used without any automatic
          element gathering.'
    defaultto []

    def is_to_s(value)
      value.inspect
    end

    def should_to_s(value)
      value.inspect
    end
  end

  newproperty(:logger) do
    desc 'The Hiera logger type.'
    newvalues 'noop', 'puppet', 'console'
    defaultto 'noop'
    munge do |value|
      value.to_s
    end
  end

  newproperty(:merge_behavior) do
    desc 'Merge strategy for hash lookups.'
    newvalues 'native', 'deep', 'deeper'
    defaultto 'native'
    munge do |value|
      value.to_s
    end
  end

  newproperty(:backends, :array_matching => :all) do
    desc 'The list of Hiera backends'
    defaultto ['yaml']
  end

  newproperty(:additions) do
    desc 'Additional configuration options to merge with the generated Hiera config file.
          Will not override the existing managed config values.'

    validate do |value|
      fail "Additional config options should be a Hash! Got: #{value.inspect}" unless value.is_a? Hash
    end

    munge do |hash|
      additions = {}
      hash.each do |key, value|
        key = key.to_s.to_sym
        next if resource.managed_keys.include? key
        additions.store key, value
      end
      additions
    end

    def is_to_s(value)
      value.inspect
    end

    def should_to_s(value)
      value.inspect
    end

    defaultto {}
  end

  # managed config file keys
  # @return [Array]
  def managed_keys
    [:logger, :backends, :yaml, :hierarchy, :merge_behavior]
  end

end
