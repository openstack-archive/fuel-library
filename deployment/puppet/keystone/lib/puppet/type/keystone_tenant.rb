# LP#1408531
File.expand_path('../..', File.dirname(__FILE__)).tap { |dir| $LOAD_PATH.unshift(dir) unless $LOAD_PATH.include?(dir) }
File.expand_path('../../../../openstacklib/lib', File.dirname(__FILE__)).tap { |dir| $LOAD_PATH.unshift(dir) unless $LOAD_PATH.include?(dir) }

Puppet::Type.newtype(:keystone_tenant) do

  desc 'This type can be used to manage keystone tenants.'

  ensurable

  newparam(:name, :namevar => true) do
    desc 'The name of the tenant.'
    newvalues(/\w+/)
  end

  newproperty(:enabled) do
    desc 'Whether the tenant should be enabled. Defaults to true.'
    newvalues(/(t|T)rue/, /(f|F)alse/, true, false )
    defaultto(true)
    munge do |value|
      value.to_s.downcase.to_sym
    end
  end

  newproperty(:description) do
    desc 'A description of the tenant.'
    defaultto('')
  end

  newproperty(:id) do
    desc 'Read-only property of the tenant.'
    validate do |v|
      raise(Puppet::Error, 'This is a read only property')
    end
  end

  # This ensures the service is started and therefore the keystone
  # config is configured IF we need them for authentication.
  # If there is no keystone config, authentication credentials
  # need to come from another source.
  autorequire(:service) do
    ['keystone']
  end
end
