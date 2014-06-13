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
    defaultto('RegionOne')
  end

  # TODO I should do some url validation
  newproperty(:public_url) do
  end

  newproperty(:internal_url) do
  end

  newproperty(:admin_url) do
  end

  # we should not do anything until the keystone service is started
  autorequire(:service) do
    ['keystone']
  end

  autorequire(:keystone_service) do
    if self[:name].match('/')
      (region, service_name) = self[:name].split('/')
      [service_name]
    else
      [self[:name]]
    end
  end

end
