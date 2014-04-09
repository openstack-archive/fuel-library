Puppet::Type.newtype(:l2_nsx_bridge) do
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
      desc "Allow to skip existing bridge"
    end

    newproperty(:external_ids) do
      desc "External IDs for the bridge"
    end

    newproperty(:in_band) do
      desc "Enable/Disable in-band mode"
    end

    newproperty(:fail_mode) do
      desc "Fail mode configuration for bridge"
    end
end
