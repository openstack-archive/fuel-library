# LP#1408531
File.expand_path('../..', File.dirname(__FILE__)).tap { |dir| $LOAD_PATH.unshift(dir) unless $LOAD_PATH.include?(dir) }
File.expand_path('../../../../openstacklib/lib', File.dirname(__FILE__)).tap { |dir| $LOAD_PATH.unshift(dir) unless $LOAD_PATH.include?(dir) }

Puppet::Type.newtype(:keystone_domain) do

  desc <<-EOT
    This type can be used to manage
    keystone domains.
  EOT

  ensurable

  newparam(:name, :namevar => true) do
    newvalues(/\w+/)
  end

  newproperty(:enabled) do
    newvalues(/(t|T)rue/, /(f|F)alse/, true, false )
    defaultto(true)
    munge do |value|
      value.to_s.downcase.to_sym
    end
  end

  newproperty(:description)

  newproperty(:is_default) do
    desc <<-EOT
      If this is true, this is the default domain used for v2.0 requests when the domain
      is not specified, or used by v3 providers if no other domain is specified.  The id
      of this domain will be written to the keystone config identity/default_domain_id
      value.
    EOT
    newvalues(/(t|T)rue/, /(f|F)alse/, true, false )
    defaultto(false)
    munge do |value|
      value.to_s.downcase.to_sym
    end
  end

  newproperty(:id) do
    validate do |v|
      raise(Puppet::Error, 'This is a read only property')
    end
  end

  # we should not do anything until the keystone service is started
  autorequire(:service) do
    'keystone'
  end


end
