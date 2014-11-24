Puppet::Type.newtype(:nova_secgroup) do
  desc "Manage, create and delete nova security groups"

  ensurable

  newparam(:name, :namevar => true) do
    desc "Name of the security group"
  end

  newparam(:auth_username) do
    desc "Name of the user to auth against keystone"
  end

  newparam(:auth_password) do
    desc "Password of the user to auth against keystone"
  end

  newparam(:auth_tenant) do
    desc "Tenant of the user to auth"
  end

  newparam(:auth_url) do
    desc "URL of keystone to auth"
  end

  newproperty(:description) do
    desc "Description of the security group"
    defaultto ''
  end
end
