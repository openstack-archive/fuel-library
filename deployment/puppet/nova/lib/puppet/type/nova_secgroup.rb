Puppet::Type.newtype(:nova_secgroup) do
  desc "Manage, create and delete nova security groups"

  ensurable

  newparam(:name, :namevar => true) do
    desc "Name of the security group"
  end

  newproperty(:description) do
    desc "Description of the security group"
    defaultto ''
  end
end
