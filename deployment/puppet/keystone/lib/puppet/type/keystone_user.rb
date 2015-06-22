# LP#1408531
File.expand_path('../..', File.dirname(__FILE__)).tap { |dir| $LOAD_PATH.unshift(dir) unless $LOAD_PATH.include?(dir) }
File.expand_path('../../../../openstacklib/lib', File.dirname(__FILE__)).tap { |dir| $LOAD_PATH.unshift(dir) unless $LOAD_PATH.include?(dir) }

Puppet::Type.newtype(:keystone_user) do

  desc 'Type for managing keystone users.'

  ensurable

  newparam(:name, :namevar => true) do
    newvalues(/\S+/)
  end

  newparam(:ignore_default_tenant) do
    newvalues(/(t|T)rue/, /(f|F)alse/, true, false)
    defaultto(false)
    munge do |value|
      value.to_s.downcase.to_sym
    end
  end

  newproperty(:enabled) do
    newvalues(/(t|T)rue/, /(f|F)alse/, true, false)
    defaultto(true)
    munge do |value|
      value.to_s.downcase.to_sym
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
    newvalues(/^(\S+@\S+)|$/)
  end

  newproperty(:id) do
    validate do |v|
      raise(Puppet::Error, 'This is a read only property')
    end
  end

  newparam(:replace_password) do
    newvalues(/(t|T)rue/, /(f|F)alse/, true, false)
    defaultto(true)
    munge do |value|
      value.to_s.downcase.to_sym
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
