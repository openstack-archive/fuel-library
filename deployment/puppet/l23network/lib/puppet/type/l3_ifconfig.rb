# type for managing runtime IP addresses and another L3 stuff.

require 'puppet/property/boolean'

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

    newproperty(:port_type) do
      desc "Internal read-only property"
      validate do |value|
        raise ArgumentError, "You shouldn't change port_type -- it's a internal RO property!"
      end
    end

    newproperty(:ipaddr, :array_matching => :all) do
      desc "List of IP address for this interface"
      newvalues(/^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})(\/(\d{1,2}))?$/, :absent, :none, :undef, :nil)
      aliasvalue(:absent, :none)
      aliasvalue(:absent, :undef)
      aliasvalue(:absent, :nil)
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
      aliasvalue(:absent, :none)
      aliasvalue(:absent, :undef)
      aliasvalue(:absent, :nil)
      defaultto(:absent)
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
      aliasvalue(:absent, :none)
      aliasvalue(:absent, :undef)
      aliasvalue(:absent, :nil)
      defaultto(:absent)
      validate do |val|
        if val.to_sym != :absent and val.to_i < 0
          raise ArgumentError, "Invalid gateway metric: '#{val}'"
        end
      end
      munge do |val|
        (val.to_sym == :absent)  ?  :absent  :  val.to_i
      end
    end

    newproperty(:dhcp_hostname) do
      desc "DHCP hostname"
    end

    # newproperty(:onboot, :parent => Puppet::Property::Boolean) do
    #   desc "Whether to bring the interface up"
    #   defaultto :true
    # end

    autorequire(:l2_port) do
      [self[:interface]]
    end
end
# vim: set ts=2 sw=2 et :