Puppet::Type.newtype(:neutron_metadata_agent_config) do
  ensurable

  newparam(:name, :namevar => true) do
    newvalues(/\S+\/\S+/)
  end

  newproperty(:value) do
    munge do |value|
      value = value.to_s.strip
      if value =~ /^(true|false)$/i
        value.capitalize!
      end
      value
    end
  end
end