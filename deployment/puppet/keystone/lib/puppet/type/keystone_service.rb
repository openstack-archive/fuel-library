# LP#1408531
File.expand_path('../..', File.dirname(__FILE__)).tap { |dir| $LOAD_PATH.unshift(dir) unless $LOAD_PATH.include?(dir) }
File.expand_path('../../../../openstacklib/lib', File.dirname(__FILE__)).tap { |dir| $LOAD_PATH.unshift(dir) unless $LOAD_PATH.include?(dir) }

Puppet::Type.newtype(:keystone_service) do

  desc 'This type can be used to manage keystone services.'

  ensurable

  newparam(:name, :namevar => true) do
    desc 'The name of the service.'
    newvalues(/\S+/)
  end

  newproperty(:id) do
    validate do |v|
      raise(Puppet::Error, 'This is a read only property')
    end
  end

  newproperty(:type) do
    desc 'The type of service'
    validate do |value|
      fail('The service type is required.') unless value
    end
  end

  newproperty(:description) do
    desc 'A description of the service.'
    defaultto('')
  end

  # This ensures the service is started and therefore the keystone
  # config is configured IF we need them for authentication.
  # If there is no keystone config, authentication credentials
  # need to come from another source.
  autorequire(:service) do
    ['keystone']
  end
end
