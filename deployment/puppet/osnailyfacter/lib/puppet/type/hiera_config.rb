Puppet::Type.newtype(:hiera_config) do
  desc 'Manage Hiera yaml configuration'

  newparam(:name) do
    desc 'The path to the Hiera config file'
    isnamevar
  end

  newparam(:override_dir) do
    desc 'Look for override files in this directory.
         The directory path should be relative to the basic data directory.'
    defaultto 'plugins'
  end

  newparam(:metadata_yaml_file) do
    desc 'Look inside this YAML file for enabled plugins'
  end

  newproperty(:data_dir) do
    desc 'Basic directory with Hiera data elements'
    defaultto '/etc/hiera'
  end

  newproperty(:hierarchy, :array_matching => :all) do
    desc 'Basic hierarchy elements'
    defaultto []

    def is_to_s(value)
      value.inspect
    end

    def should_to_s(value)
      value.inspect
    end
  end

  newproperty(:hierarchy_override, :array_matching => :all) do
    desc 'Override hierarhy elements'
    defaultto []

    def is_to_s(value)
      value.inspect
    end

    def should_to_s(value)
      value.inspect
    end
  end

  newproperty(:logger) do
    desc 'The Hiera logger type'
    newvalues 'noop', 'puppet', 'console'
    defaultto 'noop'
    munge do |value|
      value.to_s
    end
  end

  newproperty(:merge_behavior) do
    desc 'Merge strategy for hash lookups'
    newvalues 'native', 'deep', 'deeper'
    defaultto 'native'
    munge do |value|
      value.to_s
    end
  end

end
