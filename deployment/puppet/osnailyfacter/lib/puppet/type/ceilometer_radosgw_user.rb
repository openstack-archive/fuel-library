Puppet::Type.newtype(:ceilometer_radosgw_user) do
  @doc = "Manage a RadosGW user for Ceilometer"

  ensurable do
    defaultto :present

    newvalue(:present) do
      provider.create
    end
  end

  newparam(:name) do
    desc "The Ceilometer user name in RadosGW"
    defaultto 'ceilometer'
  end

  newparam(:caps) do
    desc "Roles for the user"
    defaultto {}

    validate do |value|
      fail 'Caps should contain hash' unless value.is_a? Hash
    end
  end
end
