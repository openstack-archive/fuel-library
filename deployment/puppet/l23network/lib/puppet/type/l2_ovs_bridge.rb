Puppet::Type.newtype(:l2_ovs_bridge) do
    @doc = "Manage a Open vSwitch bridge (virtual switch)"
    desc @doc

    ensurable

    newparam(:bridge) do
      isnamevar
      desc "The bridge to configure"
      #
      validate do |val|
        if not val =~ /^[a-z][0-9a-z\.\-\_]*[0-9a-z]$/
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
