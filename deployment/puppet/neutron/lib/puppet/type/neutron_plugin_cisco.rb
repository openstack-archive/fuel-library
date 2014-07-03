Puppet::Type.newtype(:neutron_plugin_cisco) do

  ensurable

  newparam(:name, :namevar => true) do
    desc 'Section/setting name to manage from cisco_plugins.ini'
    newvalues(/\S+\/\S+/)
  end

  autorequire(:file) do
    ['/etc/neutron/plugins/cisco']
  end

  newproperty(:value) do
    desc 'The value of the setting to be defined.'
    munge do |value|
      value = value.to_s.strip
      value.capitalize! if value =~ /^(true|false)$/i
      value
    end
  end
end
