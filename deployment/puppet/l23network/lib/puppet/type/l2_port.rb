# type for managing runtime NIC states.

require 'puppet/property/boolean'

Puppet::Type.newtype(:l2_port) do
    @doc = "Manage a network port abctraction."
    desc @doc

    ensurable

    newparam(:interface) do
      isnamevar
      desc "The interface name"
      #
      validate do |val|
        if not val =~ /^[a-z_][0-9a-z\.\-\_]*[0-9a-z]$/
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

    newproperty(:onboot, :parent => Puppet::Property::Boolean) do
      desc "Whether to bring the interface up"
      defaultto :true
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

    newproperty(:vlan_dev) do
      desc "802.1q vlan base device"
    end

    newproperty(:vlan_id) do
      desc "802.1q vlan ID"
      validate do |value|
        unless (value =~ /^\d+$/)
          raise ArgumentError, "#{value} is not a valid VLAN_ID (must be a positive integer)"
        end
        min_id = 2
        max_id = 4094
        unless (min_id .. max_id).include?(value.to_i)
          raise ArgumentError, "#{value} is not in the valid VLAN_ID (#{min_mtu} .. #{max_mtu})"
        end
      end
    end

    newproperty(:vlan_mode) do
      desc "802.1q vlan interface naming model"
      #newvalues(:ethernet, :bridge, :bond)
      #defaultto :ethernet
    end

    newparam(:trunks, :array_matching => :all) do
      defaultto([])
      desc "Array of trunks id, for configure patch's ends as ports in trunk mode"
      #
      # validate do |val|
      #   val = Array(val)  # prevents puppet conversion array of one Int to Int
      #   for i in val
      #     if !i.is_a?(Integer) or (i < 0 or i > 4094)
      #       fail("Wrong 802.1q tag. Tag must be an integer in 2..4094 interval")
      #     end
      #   end
      # end
      munge do |val|
        Array(val)
      end
    end

    newproperty(:mtu) do
      desc "The Maximum Transmission Unit size to use for the interface"
      validate do |value|
        # reject floating point and negative integers
        # XXX this lets 1500.0 pass
        unless (value =~ /^\d+$/)
          raise ArgumentError, "#{value} is not a valid mtu (must be a positive integer)"
        end

        # Intel 82598 & 82599 chips support MTUs up to 16110; is there any
        # hardware in the wild that supports larger frames?
        #
        # It appears loopback devices routinely have large MTU values; Eg. 65536
        #
        # Frames small than 64bytes are discarded as runts.  Smallest valid MTU
        # is 42 with a 802.1q header and 46 without.
        min_mtu = 42
        max_mtu = 65536
        unless (min_mtu .. max_mtu).include?(value.to_i)
          raise ArgumentError, "#{value} is not in the valid mtu range (#{min_mtu} .. #{max_mtu})"
        end
      end
    end

    newparam(:vlan_splinters) do
      newvalues(true, false)
      defaultto(false)
      desc "Enable vlan splinters (if it's a phys. interface)"
    end

    autorequire(:l2_bridge) do
      [self[:bridge]]
    end
end
