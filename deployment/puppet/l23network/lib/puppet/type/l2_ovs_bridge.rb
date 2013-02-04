Puppet::Type.newtype(:l2_ovs_bridge) do
    @doc = "Manage a Open vSwitch bridge (virtual switch)"
    desc @doc

    ensurable

    newparam(:bridge) do
      isnamevar
      desc "The bridge to configure"
      #
      validate do |val|
        if not val =~ /^[0-9A-Za-z\.\-\_]+$/
          fail("Invalid bridge name: '#{val}'")
        end
      end
    end

    newparam(:skip_existing) do
      defaultto(false)
      desc "Allow skip existing bridge"
    end

    newproperty(:external_ids) do
      desc "External IDs for the bridge"
    end
end
