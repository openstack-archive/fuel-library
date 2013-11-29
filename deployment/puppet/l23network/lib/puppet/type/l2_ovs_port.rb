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

    newparam(:port_properties) do
      defaultto([])
      desc "Array of port properties"
      validate do |val|
        if not (val.is_a?(Array) or val.is_a?(String)) # String need for array with one element. it's a puppet's feature
          fail("port_properties must be an array (not #{val.class}).")
        end
      end
      munge do |val|
        if val.is_a?(String)
          [val]
        else
          val
        end
      end
    end

    newparam(:interface_properties) do
      defaultto([])
      desc "Array of port interface properties"
      validate do |val|
        if not (val.is_a?(Array) or val.is_a?(String)) # String need for array with one element. it's a puppet's feature
          fail("interface_properties must be an array (not #{val.class}).")
        end
      end
      munge do |val|
        if val.is_a?(String)
          [val]
        else
          val
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

    newparam(:vlan_splinters) do
      newvalues(true, false)
      defaultto(false)
      desc "Enable vlan splinters (if it's a phys. interface)"
    end


    autorequire(:l2_ovs_bridge) do
      [self[:bridge]]
    end
end
