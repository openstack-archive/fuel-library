Puppet::Type.newtype(:l2_patch) do
    @doc = "Manage a patchcords between two bridges"
    desc @doc

    ensurable

    newparam(:name) # workarround for following error:
    # Error 400 on SERVER: Could not render to pson: undefined method `merge' for []:Array
    # http://projects.puppetlabs.com/issues/5220

    newparam(:use_ovs) do
      desc "Whether using OVS comandline tools"
      newvalues(:true, :yes, :on, :false, :no, :off)
      aliasvalue(:yes, :true)
      aliasvalue(:on,  :true)
      aliasvalue(:no,  :false)
      aliasvalue(:off, :false)
      defaultto :true
    end

    newproperty(:bridges, :array_matching => :all) do
      desc "Array of bridges that will be connected"
      newvalues(/^[a-z][0-9a-z\-\_]*[0-9a-z]$/)
    end

    newproperty(:jacks, :array_matching => :all) do
      desc "Patchcord jacks. Read-only. for debug purpose."
    end

    newproperty(:cross) do
      desc "Cross-system patch. Read-only. for debug purpose."
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
      self[:bridges]
    end
end
# vim: set ts=2 sw=2 et :