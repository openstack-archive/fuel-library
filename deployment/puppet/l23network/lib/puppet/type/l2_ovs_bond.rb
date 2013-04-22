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

    newparam(:ports) do
      desc "List of ports, that will be added to the bond"
      #
      validate do |val|
        if not val.is_a?(Array)
          fail("Ports option must be array (not be #{val.class}).")
        end
        for port in val
          if not port =~ /^[a-z][0-9a-z\.\-\_]*[0-9a-z]$/
            fail("Invalid port name: '#{port}'")
          end
        end
      end
    end

    newparam(:skip_existing) do
      defaultto(false)
      desc "Allow skip existing bond"
    end

    newparam(:options) do
      defaultto([])
      desc "Array of bond options"
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

    autorequire(:l2_ovs_bridge) do
      [self[:bridge]]
    end
end
