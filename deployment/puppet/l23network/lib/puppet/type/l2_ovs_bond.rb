Puppet::Type.newtype(:l2_ovs_bond) do
    @doc = "Manage a Open vSwitch port"
    desc @doc

    ensurable

    newparam(:bond) do
      isnamevar
      desc "The bond name"
      #
      validate do |val|
        if not val =~ /^[a-z][0-9a-z\.\-\_]*[0-9a-z]$/
          fail("Invalid bond name: '#{val}'")
        end
      end
    end

    newparam(:interfaces) do
      desc "List of interfaces that will be added to the bond"
      #
      validate do |val|
        if not val.is_a?(Array)
          fail("Interfaces parameter must be an array (not #{val.class}).")
        end
        for ii in val
          if not ii =~ /^[a-z][0-9a-z\.\-\_]*[0-9a-z]$/
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

    newparam(:tag) do
      defaultto(0)
      desc "802.1q tag"
      validate do |val|
        if not (val.is_a?(Integer) or val.is_a?(String))
          fail("tag must be an integer (not #{val.class}).")
        end
        v = val.to_i
        if v < 0 or v > 4094
          fail("tag must be an integer in 2..4094 interval")
        end
      end
      munge do |val|
        val.to_i
      end
    end

    newparam(:trunks) do
      defaultto([])
      desc "Array of trunks id, for configure port in trunk mode"
      validate do |val|
        if not (val.is_a?(Array) or val.is_a?(String) or val.is_a?(Integer)) # String need for array with one element. it's a puppet's feature
          fail("trunks must be an array (not #{val.class}).")
        end
      end

      munge do |val|
        if val.is_a?(String)
          [val.to_i]
        elsif val.is_a?(Integer)
          if val >= 0 and val < 4095
            [val]
          else
            []
          end
        else
          val
        end
      end
    end

    autorequire(:l2_ovs_bridge) do
      [self[:bridge]]
    end
end
