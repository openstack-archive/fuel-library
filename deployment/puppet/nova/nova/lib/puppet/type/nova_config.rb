Puppet::Type.newtype(:nova_config) do

  ensurable 

  newparam(:name, :namevar => true) do
    newvalues(/\S+/)
  end

  newproperty(:value) do
    newvalues(/\S+/)
  end

  newproperty(:target) do
    desc "Path to our nova config file"
    defaultto { 
      if @resource.class.defaultprovider.ancestors.include?(Puppet::Provider::ParsedFile)
        @resource.class.defaultprovider.default_target
      else
        nil
      end
    }
  end

end
