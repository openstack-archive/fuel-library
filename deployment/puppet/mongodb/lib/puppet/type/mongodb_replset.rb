#
# Author: François Charlier <francois.charlier@enovance.com>
#

Puppet::Type.newtype(:mongodb_replset) do
  @doc = "Manage a MongoDB replicaSet"

  ensurable do
    defaultto :present

    newvalue(:present) do
      provider.create
    end
  end

  newparam(:name) do
    desc "The name of the replicaSet"
  end

  newparam(:arbiter) do
    desc "The replicaSet arbiter"
  end

  newparam(:admin_username) do
    desc "Administrator user login"
    defaultto false
  end

  newparam(:admin_password) do
    desc "Administrator user password"
    defaultto false
  end

  newparam(:admin_database) do
    desc "Connect to this database as an admin user."
    defaultto false
  end

  newparam(:auth_enabled) do
    desc "Check authentication enabled"
    defaultto false
  end

  newproperty(:members, :array_matching => :all) do
    desc "The replicaSet members"

    def insync?(is)
      is.sort == should.sort
    end
  end

  autorequire(:package) do
    'mongodb_client'
  end

  autorequire(:service) do
    'mongodb'
  end
end
