Puppet::Type.newtype(:keystone_user) do

  desc <<-EOT
    This is currently used to model the creation of
    keystone users.

    It currently requires that both the password
    as well as the tenant are specified.
  EOT

# TODO support description??

  ensurable

  newparam(:name, :namevar => true) do
    newvalues(/\S+/)
  end

  newproperty(:enabled) do
    newvalues(/(t|T)rue/, /(f|F)alse/)
    defaultto('True')
    munge do |value|
      value.to_s.capitalize
    end
  end

  newparam(:password) do
    newvalues(/\S+/)
  end

  newproperty(:tenant) do
    newvalues(/\S+/)
  end

  newproperty(:email) do
    newvalues(/\S+@\S+/)
  end

  newproperty(:id) do
    validate do |v|
      raise(Puppet::Error, 'This is a read only property')
    end
  end

  autorequire(:keystone_tenant) do
    self[:tenant]
  end

  # we should not do anything until the keystone service is started
  autorequire(:service) do
    ['keystone']
  end

end
