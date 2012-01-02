Puppet::Type.newtype(:keystone_role) do

  desc <<-EOT
    Type to create new keystone roles.
  EOT

  ensurable

  newparam(:name, :namevar => true) do
  end

  newproperty(:id) do
  end

  newproperty(:service) do
  end

  newproperty(:description) do
  end
end
