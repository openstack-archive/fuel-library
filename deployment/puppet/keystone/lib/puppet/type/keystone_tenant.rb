Puppet::Type.newtype(:keystone_tenant) do

  desc <<-EOT
    This type can be used to manage
    keystone tenants.

    This is assumed to be running on the same node
    as your keystone API server.
  EOT

  ensurable

  newparam(:name, :namevar => true) do
    newvalues(/\w+/)
  end

  newproperty(:enabled) do
    newvalues(/(t|T)rue/, /(f|F)alse/)
    defaultto('True')
    munge do |value|
      value.to_s.capitalize
    end
  end

  newproperty(:description) do
  end

  newproperty(:id) do
    validate do |v|
      raise(Puppet::Error, 'This is a read only property')
    end
  end

  # we should not do anything until the keystone service is started
  autorequire(:service) do
    ['keystone']
  end

end
