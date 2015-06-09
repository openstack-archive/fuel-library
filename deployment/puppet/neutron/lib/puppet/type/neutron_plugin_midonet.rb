Puppet::Type.newtype(:neutron_plugin_midonet) do

  ensurable

  newparam(:name, :namevar => true) do
    desc 'Section/setting name to manage from midonet.ini'
    newvalues(/\S+\/\S+/)
  end

  autorequire(:file) do
    ['/etc/neutron/plugins/midonet']
  end

  autorequire(:package) do ['neutron'] end

  newproperty(:value) do
    desc 'The value of the setting to be defined.'
    munge do |value|
      value = value.to_s.strip
      value.capitalize! if value =~ /^(true|false)$/i
      value
    end

    def is_to_s( currentvalue )
      if resource.secret?
        return '[old secret redacted]'
      else
        return currentvalue
      end
    end

    def should_to_s( newvalue )
      if resource.secret?
        return '[new secret redacted]'
      else
        return newvalue
      end
    end
  end

  newparam(:secret, :boolean => true) do
    desc 'Whether to hide the value from Puppet logs. Defaults to `false`.'

    newvalues(:true, :false)

    defaultto false
  end

end
