Puppet::Type.newtype(:keystone_user) do

  desc <<-EOT

    This is currently used to model the creation of
    keystone users.

    It currently requires that both the password
    as well as the tenant are specified.

  EOT

  newparam(:name, :namevar => true) do
    newvalues(/\S+/)
  end

  newparam(:password) do
    newvalues(/\S+/)
  end

  newproperty(:tenant) do
    newvalues(/\S+/)
  end


end
