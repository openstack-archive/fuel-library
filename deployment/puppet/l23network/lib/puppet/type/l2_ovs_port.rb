Puppet::Type.newtype(:l2_ovs_port) do
    @doc = "Manage a Open vSwitch port"
    desc @doc

    ensurable

    newparam(:interface) do
      isnamevar
      desc "The interface to attach to the bridge"
      #
      validate do |val|
        if not val =~ /^[a-z][0-9a-z\.\-\_]*[0-9a-z]$/
          fail("Invalid interface name: '#{val}'")
        end
      end
    end

    newparam(:type) do
      newvalues('', :system, :internal, :tap, :gre, :ipsec_gre, :capwap, :patch, :null)
      defaultto('')
      desc "Ovs port type"
    end

    newparam(:skip_existing) do
      defaultto(false)
      desc "Allow to skip existing port"
    end

    newparam(:bridge) do
      desc "What bridge to use"
      #
      validate do |val|
        if not val =~ /^[a-z][0-9a-z\.\-\_]*[0-9a-z]$/
          fail("Invalid bridge name: '#{val}'")
        end
      end
    end

    newparam(:port_properties, :array_matching => :all) do
      defaultto([])
      desc "Array of port properties"
      munge do |val|
        Array(val)
      end
    end

    newparam(:interface_properties) do
      defaultto([])
      desc "Array of port interface properties"
      munge do |val|
        Array(val)
      end
    end

    newparam(:tag) do
      defaultto(0)
      desc "802.1q tag"
      validate do |val|
        if !val.is_a?(Integer) or (val < 0 or val > 4094)
          fail("Wrong 802.1q tag. Tag must be an integer in 2..4094 interval")
        end
      end
      munge do |val|
        val.to_i
      end
    end

    newparam(:trunks, :array_matching => :all) do
      defaultto([])
      desc "Array of trunks id, for configure patch's ends as ports in trunk mode"
      #
      validate do |val|
        val = Array(val)  # prevents puppet conversion array of one Int to Int
        for i in val
          if !i.is_a?(Integer) or (i < 0 or i > 4094)
            fail("Wrong 802.1q tag. Tag must be an integer in 2..4094 interval")
          end
        end
      end
      munge do |val|
        Array(val)
      end
    end

    newparam(:vlan_splinters) do
      newvalues(true, false)
      defaultto(false)
      desc "Enable vlan splinters (if it's a phys. interface)"
    end

    autorequire(:l2_ovs_bridge) do
      [self[:bridge]]
    end
end
