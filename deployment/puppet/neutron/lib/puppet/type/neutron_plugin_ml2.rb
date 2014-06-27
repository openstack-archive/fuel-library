Puppet::Type.newtype(:neutron_plugin_ml2) do

  ensurable

  newparam(:name, :namevar => true) do
    desc 'Section/setting name to manage from ml2_conf.ini'
    newvalues(/\S+\/\S+/)
  end

  autorequire(:package) do ['neutron'] end

  newproperty(:value) do
    desc 'The value of the setting to be defined.'
    munge do |value|
      value = value.to_s.strip
      value.capitalize! if value =~ /^(true|false)$/i
      value
    end
  end
end
