# type for managing runtime NIC states.

require 'yaml'
require 'puppetx/l23_utils'

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

    newparam(:use_ovs) do
      desc "Whether using OVS comandline tools"
      newvalues(:true, :yes, :on, :false, :no, :off)
      aliasvalue(:yes, :true)
      aliasvalue(:on,  :true)
      aliasvalue(:no,  :false)
      aliasvalue(:off, :false)
      defaultto :true
    end

    #todo(sv): move to provider_specific hash
    newproperty(:type) do
      newvalues(:system, :internal, :tap, :gre, :ipsec_gre, :capwap, :patch, :null, :undef, :nil, :none)
      aliasvalue(:none,  :internal)
      aliasvalue(:undef, :internal)
      aliasvalue(:nil,   :internal)
      aliasvalue(:null,  :internal)
      #defaultto :internal
      desc "Port type (for openvswitch only)"
    end

    newproperty(:port_type) do
      desc "Internal read-only property"
      validate do |value|
        raise ArgumentError, "You shouldn't change port_type -- it's a internal RO property!"
      end
    end

    newproperty(:onboot) do
      desc "Whether to bring the interface up"
      newvalues(:true, :yes, :on, :false, :no, :off)
      aliasvalue(:yes, :true)
      aliasvalue(:on,  :true)
      aliasvalue(:no,  :false)
      aliasvalue(:off, :false)
      defaultto :true

      def insync?(value)
        value.to_s.downcase == should.to_s.downcase
      end
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
        if ['nil', 'undef', 'none', 'absent', ''].include?(val.to_s)
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
      aliasvalue(:none,  :absent)
      aliasvalue(:undef, :absent)
      aliasvalue(:nil,   :absent)
      aliasvalue(0,      :absent)
      defaultto :absent
      validate do |value|
        min_vid = 1
        max_vid = 4094
        if ! (value.to_s == 'absent' or (min_vid .. max_vid).include?(value.to_i))
          raise ArgumentError, "'#{value}' is not a valid 802.1q VLAN_ID (must be a integer value in range (#{min_vid} .. #{max_vid})"
        end
      end
      munge do |val|
        ((val == :absent)  ?  :absent  :  val.to_i)
      end

    end

    newproperty(:vlan_mode) do
      desc "802.1q vlan interface naming model"
    end

    newproperty(:bond_master) do
      desc "Bond name, if interface is a part of bond"
      newvalues(/^[a-z][\w\-]*$/, :absent, :none, :undef, :nil)
      aliasvalue(:none,  :absent)
      aliasvalue(:undef, :absent)
      aliasvalue(:nil,   :absent)
      defaultto :absent
    end

    newparam(:trunks, :array_matching => :all) do
      desc "Array of trunks id, for configure patch's ends as ports in trunk mode"
    end

    newproperty(:mtu) do
      desc "The Maximum Transmission Unit size to use for the interface"
      newvalues(/^\d+$/, :absent, :none, :undef, :nil)
      aliasvalue(:none,  :absent)
      aliasvalue(:undef, :absent)
      aliasvalue(:nil,   :absent)
      aliasvalue(0,      :absent)
      defaultto :absent   # MTU value should be undefined by default, because some network resources (bridges, subinterfaces)
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
        ((val == :absent)  ?  :absent  :  val.to_i)
      end

    end

    newproperty(:ethtool) do
      desc "Hash of ethtool properties"
      #defaultto {}
      # provider-specific hash, validating only by type.
      validate do |val|
        unless val.is_a? Hash
          fail 'Ethtool should be a hash!'
          if val['rings'] and not val['rings'].is_a? Hash
            fail 'Rings should be a Hash! Do you have "stringify_facts=false" in your puppet config?'
          end
        end
      end
      munge do |value|
        (value.empty?  ?  nil  :  L23network.reccursive_sanitize_hash(value))
      end

      def should_to_s(value)
        "\n#{value.to_yaml}\n"
      end

      def is_to_s(value)
        "\n#{value.to_yaml}\n"
      end

      def insync?(value)
        new_should = {}
        (value.keys + should.keys).uniq.map{|k| new_should[k] = {}}
        # debug("\nV: #{value.to_yaml}\n")
        # debug("\nS: #{should.to_yaml}\n")
        # debug("\nN: #{new_should.to_yaml}\n")
        new_should = value.merge(should) { |key, value_v, should_v| value_v.merge should_v }
        #debug("\nZ: #{new_should.to_yaml}\n")
        (L23network.reccursive_sanitize_hash(value) == L23network.reccursive_sanitize_hash(new_should))
      end
    end

    newproperty(:vendor_specific) do
      desc "Hash of vendor specific properties"
      #defaultto {}  # no default value should be!!!
      # provider-specific properties, can be validating only by provider.
      validate do |val|
        if ! val.is_a? Hash
          fail("Vendor_specific should be a hash!")
        end
      end

      munge do |value|
        (value.empty?  ?  nil  :  L23network.reccursive_sanitize_hash(value))
      end

      def should_to_s(value)
        "\n#{value.to_yaml}\n"
      end

      def is_to_s(value)
        "\n#{value.to_yaml}\n"
      end

      def insync?(value)
        should_to_s(value) == should_to_s(should)
      end
    end

    autorequire(:l2_bridge) do
      [self[:bridge]]
    end
end
# vim: set ts=2 sw=2 et :
