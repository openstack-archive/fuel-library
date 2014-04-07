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

  newproperty(:password) do
    newvalues(/\S+/)
    def change_to_s(currentvalue, newvalue)
      if currentvalue == :absent
        return "created password"
      else
        return "changed password"
      end
    end

    def is_to_s( currentvalue )
      return '[old password redacted]'
    end

    def should_to_s( newvalue )
      return '[new password redacted]'
    end
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
