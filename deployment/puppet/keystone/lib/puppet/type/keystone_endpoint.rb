# LP#1408531
File.expand_path('../..', File.dirname(__FILE__)).tap { |dir| $LOAD_PATH.unshift(dir) unless $LOAD_PATH.include?(dir) }
File.expand_path('../../../../openstacklib/lib', File.dirname(__FILE__)).tap { |dir| $LOAD_PATH.unshift(dir) unless $LOAD_PATH.include?(dir) }

Puppet::Type.newtype(:keystone_endpoint) do

  desc 'Type for managing keystone endpoints.'

  ensurable

  newparam(:name, :namevar => true) do
    newvalues(/\S+\/\S+/)
  end

  newproperty(:id) do
    validate do |v|
      raise(Puppet::Error, 'This is a read only property')
    end
  end

  newproperty(:region) do
  end

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
    (region, service_name) = self[:name].split('/')
    [service_name]
  end
end
