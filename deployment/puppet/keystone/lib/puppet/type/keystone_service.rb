Puppet::Type.newtype(:keystone_service) do

  desc <<-EOT
    This is currently used to model the management of
    keystone services.
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

  newproperty(:type) do
  end

  newproperty(:description) do
  end

  # we should not do anything until the keystone service is started
  autorequire(:service) do
    ['keystone']
  end

end
