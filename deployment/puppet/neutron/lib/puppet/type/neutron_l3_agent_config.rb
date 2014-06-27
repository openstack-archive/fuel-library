Puppet::Type.newtype(:neutron_l3_agent_config) do

  ensurable

  newparam(:name, :namevar => true) do
    desc 'Section/setting name to manage from l3_agent.ini'
    newvalues(/\S+\/\S+/)
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
