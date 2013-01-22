Puppet::Type.newtype(:ovs_bridge) do
    @doc = "Manage a Open vSwitch bridge (virtual switch)"
    desc @doc

    ensurable

    newparam(:bridge) do
      isnamevar
      desc "The bridge to configure"
    end

    newparam(:skip_existing) do
      defaultto(false)
      desc "Allow skip existing bridge"
    end

    newproperty(:external_ids) do
      desc "External IDs for the bridge"
    end


end
