module Puppet
  Puppet::Type.newtype(:ovs_bridge) do
    @doc = "Manage a Open vSwitch bridge (virtual switch)"
    desc @doc
    ensurable

    newparam(:name) do
      isnamevar
      desc "The bridge to configure"
    end

    newproperty(:external_ids) do
      desc "External IDs for the bridge"
    end

  end
end
