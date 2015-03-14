# type for managing runtime bond of NICs states.

Puppet::Type.newtype(:l2_bond) do
    @doc = "Manage a network port abctraction."
    desc @doc

    ensurable

    newparam(:bond) do
      isnamevar
      desc "The bond name"
      #
      validate do |val|
        if not val =~ /^[a-z_][\w\.\-]*[0-9a-z]$/
          fail("Invalid bond name: '#{val}'")
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
      newvalues(/^[a-z][0-9a-z\-\_]*[0-9a-z]$/, :absent, :none, :undef, :nil)
      aliasvalue(:none,  :absent)
      aliasvalue(:undef, :absent)
      aliasvalue(:nil,   :absent)
      defaultto :absent
    end

    newproperty(:slaves, :array_matching => :all) do
      desc "What bridge to use"
      newvalues(/^[a-z][0-9a-z\-\_]*[0-9a-z]$/, :absent, :none, :undef, :nil)
      aliasvalue(:none,  :absent)
      aliasvalue(:undef, :absent)
      aliasvalue(:nil,   :absent)
      defaultto :absent
      # provider-specific list. may be empty.
      def should_to_s(value)
        value == :absent  ?  value  :  value.sort.join(',')
      end
      def is_to_s(value)
        should_to_s(value)
      end
      def insync?(value)
        should_to_s(value) == should_to_s(should)
      end

    end

    newparam(:trunks, :array_matching => :all) do
      desc "Array of trunks id, for configure patch's ends as ports in trunk mode"
    end

    newproperty(:interface_properties) do
      desc "Hash of bonded interfaces properties"
      #defaultto {}
      # provider-specific hash, validating only by type.
      validate do |val|
        if ! val.is_a? Hash
          fail("Interface_properties should be a hash!")
        end
      end

      def should_to_s(value)
        return :absent if value == :absent
        rv = []
        value.keys.sort.each do |key|
          rv << "(#{key.to_s}=#{value[key]})"
        end
        rv.join(', ')
      end

      def is_to_s(value)
        should_to_s(value)
      end

      def insync?(value)
        should_to_s(value) == should_to_s(should)
      end
    end

    newproperty(:bond_properties) do
      desc "Hash of bond properties"
      #defaultto {}
      # provider-specific hash, validating only by type.
      validate do |val|
        #puts "l2_bond validate got '#{val.inspect}'"
        if ! val.is_a? Hash
          fail("Interface_properties should be a hash!")
        end
      end

      munge do |val|
        # it's a workaround, because puppet double some values inside his internal logic
        val.keys.each do |k|
          if k.is_a? String
            if ! val.has_key? k.to_sym
              val[k.to_sym] = val[k]
            end
            val.delete(k)
          end
        end
        val
      end

      def should_to_s(value)
        return '' if [:absent, 'absent', nil, {}].include? value
        value.keys.sort.map{|k| "(#{k.to_s}=#{value[k]})"}.join(', ')
      end

      def is_to_s(value)
        should_to_s(value)
      end

      def insync?(value)
        should_to_s(value) == should_to_s(should)
      end
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

    # def validate
    #   if self[:name].to_s == 'bond23'
    #     require 'pry'
    #     binding.pry
    #   end
    # end
end
# vim: set ts=2 sw=2 et :