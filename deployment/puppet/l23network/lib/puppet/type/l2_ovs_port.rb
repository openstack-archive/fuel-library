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
      desc "Allow skip existing port"
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
          fail("port_properties must be array (not be #{val.class}).")
        end
      end
    end

    newparam(:interface_properties) do
      defaultto([])
      desc "Array of port interface properties"
      validate do |val|
        if not (val.is_a?(Array) or val.is_a?(String)) # String need for array with one element. it's a puppet's feature
          fail("interface_properties must be array (not be #{val.class}).")
        end
      end
    end

    autorequire(:l2_ovs_bridge) do
      [self[:bridge]]
    end
end
