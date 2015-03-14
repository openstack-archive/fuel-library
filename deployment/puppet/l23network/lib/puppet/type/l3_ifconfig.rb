# type for managing runtime IP addresses and another L3 stuff.

require 'yaml'

Puppet::Type.newtype(:l3_ifconfig) do
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

    newproperty(:ipaddr, :array_matching => :all) do
      desc "List of IP address for this interface"
      newvalues(/^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})(\/(\d{1,2}))?$/, :absent, :none, :undef, :nil)
      aliasvalue(:none,  :absent)
      aliasvalue(:undef, :absent)
      aliasvalue(:nil,   :absent)
      validate do |val|
        return true if [:dhcp, :none, :undef, :nil, :absent].include?(val.downcase.to_sym)
        val.strip!
        raise ArgumentError, "Invalid IP address in list: '#{val}'" if \
           not val.match(/^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})(\/(\d{1,2}))?$/) \
           or not ($1.to_i >= 0  and  $1.to_i <= 255) \
           or not ($2.to_i >= 0  and  $2.to_i <= 255) \
           or not ($3.to_i >= 0  and  $3.to_i <= 255) \
           or not ($4.to_i >= 0  and  $4.to_i <= 255) \
           or not ($6.to_i >= 0  and  $6.to_i <= 32)
      end
      def should_to_s(value)
        value.inspect
      end
      def is_to_s(value)
        value.inspect
      end
    end

    newproperty(:gateway) do
      desc "Default gateway"
      newvalues(/^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$/, :absent, :none, :undef, :nil)
      aliasvalue(:none,  :absent)
      aliasvalue(:undef, :absent)
      aliasvalue(:nil,   :absent)
      defaultto :absent
      validate do |val|
        if val != :absent
          val.strip!
          raise ArgumentError, "Invalid gateway: '#{val}'" if \
             not val.match(/^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})$/) \
             or not ($1.to_i >= 0  and  $1.to_i <= 255) \
             or not ($2.to_i >= 0  and  $2.to_i <= 255) \
             or not ($3.to_i >= 0  and  $3.to_i <= 255) \
             or not ($4.to_i >= 0  and  $4.to_i <= 255)
        end
      end
    end
    newproperty(:gateway_metric) do
      desc "Default gateway metric"
      newvalues(/^\d+$/, :absent, :none, :undef, :nil)
      aliasvalue(:none,  :absent)
      aliasvalue(:undef, :absent)
      aliasvalue(:nil,   :absent)
      defaultto :absent
      validate do |val|
        min_metric = 0
        max_metric = 65535
        if ! (val.to_s == 'absent' or (min_metric .. max_metric).include?(val.to_i))
          raise ArgumentError, "'#{val}' is not a valid metric (must be a integer value in range (#{min_metric} .. #{max_metric})"
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

    newproperty(:dhcp_hostname) do
      desc "DHCP hostname"
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

    autorequire(:l2_port) do
      [self[:interface]]
    end
end
# vim: set ts=2 sw=2 et :