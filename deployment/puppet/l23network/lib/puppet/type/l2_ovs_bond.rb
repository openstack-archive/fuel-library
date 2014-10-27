Puppet::Type.newtype(:l2_ovs_bond) do
    @doc = "Manage a Open vSwitch port"
    desc @doc

    ensurable

    newparam(:bond) do
      isnamevar
      desc "The bond name"
      #
      validate do |val|
        if not (val =~ /^[a-zA-Z][0-9a-zA-Z\.\-\_]*[0-9a-zA-Z]$/)
          fail("Invalid bond name: '#{val}'")
        end
      end
    end

    newparam(:interfaces) do
      desc "List of interfaces that will be added to the bond"
      #
      validate do |val|
        if not (val.is_a?(Array) and val.size() >= 2)
          fail("Interfaces parameter must be an array of two or more interface names.")
        end
        for ii in val
          if not (ii =~ /^[a-zA-Z][0-9a-zA-Z\.\-\_]*[0-9a-zA-Z]$/)
            fail("Invalid port name: '#{ii}'")
          end
        end
      end
    end

    newparam(:skip_existing) do
      defaultto(false)
      desc "Allow to skip existing bond"
    end

    newparam(:properties) do
      defaultto([])
      desc "Array of bond properties"
      munge do |val|
        Array(val)
      end
    end

    newparam(:bridge) do
      desc "What bridge to use"
      #
      validate do |val|
        if not (val =~ /^[a-zA-Z][0-9a-zA-Z\.\-\_]*[0-9a-zA-Z]$/)
          fail("Invalid bridge name: '#{val}'")
        end
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

    autorequire(:l2_ovs_bridge) do
      [self[:bridge]]
    end
end
