Puppet::Type.newtype(:keystone_endpoint) do

  desc <<-EOT

    This is currently used to model the management of
    keystone endpoint.

  EOT

  ensurable

  newparam(:name, :namevar => true) do
    newvalues(/\S+/)
  end

  newproperty(:id) do
    validate do |v|
      raise(Puppet::Error, 'This is a read only property')
    end
  end

  newproperty(:region) do  
    defaultto('regionOne')
  end

  newproperty(:public_url) do

  end

  newproperty(:internal_url) do
  end

  newproperty(:admin_url) do
  end

end
