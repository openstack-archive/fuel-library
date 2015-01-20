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
        if not val =~ /^[a-z_][\w\.\-]*[0-9a-z]$/
          fail("Invalid interface name: '#{val}'")
        end
      end
    end

    newparam(:type) do
      newvalues('', :system, :internal, :tap, :gre, :ipsec_gre, :capwap, :patch, :null)
      defaultto('')
      desc "Ovs port type"
    end

    newproperty(:port_type) do
      desc "Internal read-only property"
      validate do |value|
        raise ArgumentError, "You shouldn't change port_type -- it's a internal RO property!"
      end
    end

    newparam(:skip_existing) do
      defaultto(false)
      desc "Allow to skip existing port"
    end

    newproperty(:onboot, :parent => Puppet::Property::Boolean) do
      desc "Whether to bring the interface up"
      defaultto :true
    end

    newproperty(:bridge) do
      desc "What bridge to use"
      #
      validate do |val|
        if not val =~ /^[a-z][0-9a-z\-\_]*[0-9a-z]$/
          fail("Invalid bridge name: '#{val}'")
        end
      end
      munge do |val|
        if [:nil, :undef, :none, :absent].include?(val.to_sym)
          :absent
        else
          val
        end
      end
    end

    newparam(:port_properties, :array_matching => :all) do
      desc "Array of port properties"
      defaultto []
    end

    newparam(:interface_properties, :array_matching => :all) do
      desc "Array of port interface properties"
      defaultto []
    end

    newproperty(:vlan_dev) do
      desc "802.1q vlan base device"
    end

    newproperty(:vlan_id) do
      desc "802.1q vlan ID"
      newvalues(/^\d+$/, :absent, :none, :undef, :nil)
      aliasvalue(:absent, :none)
      aliasvalue(:absent, :undef)
      aliasvalue(:absent, :nil)
      defaultto(:absent)
      validate do |value|
        min_vid = 1
        max_vid = 4094
        if ! (value.to_s == 'absent' or (min_vid .. max_vid).include?(value.to_i))
          raise ArgumentError, "'#{value}' is not a valid 802.1q NALN_ID (must be a integer value in range (#{min_vid} .. #{max_vid})"
        end
      end
      munge do |val|
        if val == :absent
          :absent
        else
          begin
            val.to_i
          rescue
            :absent
          end
        end
      end
    end

    newproperty(:vlan_mode) do
      desc "802.1q vlan interface naming model"
    end

    newproperty(:bond_master) do
      desc "Bond name, if interface is a part of bond"
      newvalues(/^[a-z][\w\-]*$/, :absent, :none, :undef, :nil)
      aliasvalue(:absent, :none)
      aliasvalue(:absent, :undef)
      aliasvalue(:absent, :nil)
      defaultto(:absent)
    end

    newparam(:trunks, :array_matching => :all) do
      defaultto([])
      desc "Array of trunks id, for configure patch's ends as ports in trunk mode"
    end

    newproperty(:mtu) do
      desc "The Maximum Transmission Unit size to use for the interface"
      newvalues(/^\d+$/, :absent, :none, :undef, :nil)
      aliasvalue(:absent, :none)
      aliasvalue(:absent, :undef)
      aliasvalue(:absent, :nil)
      defaultto(:absent)  # MTU value should be undefined by default, because some network resources (bridges, subinterfaces)
      validate do |value| #     inherits it from a parent interface
        # Intel 82598 & 82599 chips support MTUs up to 16110; is there any
        # hardware in the wild that supports larger frames?
        #
        # It appears loopback devices routinely have large MTU values; Eg. 65536
        #
        # Frames small than 64bytes are discarded as runts.  Smallest valid MTU
        # is 42 with a 802.1q header and 46 without.
        min_mtu = 42
        max_mtu = 65536
        if ! (value.to_s == 'absent' or (min_mtu .. max_mtu).include?(value.to_i))
          raise ArgumentError, "'#{value}' is not a valid mtu (must be a positive integer in range (#{min_mtu} .. #{max_mtu})"
        end
      end
      munge do |val|
        if val == :absent
          :absent
        else
          begin
            val.to_i
          rescue
            :absent
          end
        end
      end
    end

    # newparam(:vlan_splinters) do
    #   newvalues(true, false)
    #   defaultto(false)
    #   desc "Enable vlan splinters (if it's a phys. interface)"
    # end

    autorequire(:l2_bridge) do
      [self[:bridge]]
    end
end
# vim: set ts=2 sw=2 et :