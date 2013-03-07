Puppet::Type.newtype(:quantum_l3_agent_routerid) do

  ensurable

  newparam(:name, :namevar => true) do
    desc 'Router name'
    newvalues(/\w+/)
  end

  newproperty(:value) do
    desc 'Id of the router'
    munge do |v|
      v.to_s.strip
    end
    def should
        provider.should
    end
  end
end
