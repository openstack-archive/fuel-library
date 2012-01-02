Puppet::Type.newtype(:keystone_tenant) do

  desc <<-EOT
    This type can be used to create
    keystone tenants.
  EOT

  ensurable

  newparam(:name, :namevar => true) do
    newvalues(/\w+/)
  end

#  newproperty(:enabled) do
#    newvalues(/(t|T)rue/, /(f|F)alse/)
#    munge do |value|
#      value.to_s.capitalize
#    end
#  end

  newproperty(:id) do
    validate do |v|
      raise(Puppet::Error, 'This is a read only property')
    end
  end
end
