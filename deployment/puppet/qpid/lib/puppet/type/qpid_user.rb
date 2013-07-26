Puppet::Type.newtype(:qpid_user) do
  desc 'Type for managing qpid users'

  ensurable do
    defaultto(:present)
    newvalue(:present) do
      provider.create
    end
    newvalue(:absent) do
      provider.destroy
    end
  end

  newparam(:name, :namevar => true) do
    desc 'Name of user'
    newvalues(/^\S+$/)
  end

  newparam(:realm) do
    desc 'Realm for this user'
    newvalues(/^\S+$/)
  end

  newparam(:file) do
    desc 'Location of the sasl password file'
    newvalues(/^\S+$/)
  end

  newparam(:password) do
    desc 'User password to be set *on creation*'
  end

  validate do
    if self[:ensure] == :present and ! self[:password]
      raise ArgumentError, 'must set password when creating user' unless self[:password]
    end
  end

end
