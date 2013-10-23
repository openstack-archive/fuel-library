Puppet::Type.newtype(:neutron_floatingip_pool) do

  @doc = "Manage creation/deletion of floating IP pool"

  ensurable

  newparam(:name) do
    desc "The name of tenant, that the pool is associated with"
    defaultto "admin"
  end

  newproperty(:pool_size) do
    desc "Size of floating IP pool"
    defaultto 1
    validate do |val|
      if val.to_i < 0
        fail("Invalid size: '#{val}'")
      end
    end
    munge do |val|
      rv = val.to_i
    end
  end

  newparam(:ext_net) do
    desc "Set an external network"
    defaultto "net04_ext"
  end

  autorequire(:package) do
    ['python-neutronclient']
  end

end
