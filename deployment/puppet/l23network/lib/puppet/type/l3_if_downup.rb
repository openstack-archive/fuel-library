Puppet::Type.newtype(:l3_if_downup) do
    @doc = "Down, flush and Up interface"
    desc @doc

    newparam(:interface) do
      isnamevar
      desc "The interface that will be down, flush and up"
      #
      validate do |val|
        if not val =~ /^[0-9A-Za-z\.\-\_]+$/
          fail("Invalid interface name: '#{val}'")
        end
      end
    end

    newparam(:flush) do
      newvalues(true, false)
      defaultto(true)
      desc "Interface will be flushed"
    end

    newparam(:refreshonly) do
      newvalues(true, false)
      defaultto(true)
    end

    newparam(:onlydown) do
      newvalues(true, false)
      defaultto(false)
    end

    newparam(:kill_dhclient) do
      # workaround for https://bugs.launchpad.net/ubuntu/+source/dhcp3/+bug/38140
      newvalues(true, false)
      defaultto(true)
    end
    newparam(:dhclient_name) do
      defaultto('dhclient3')
    end

    newparam(:sleep_time) do
      defaultto(3)
    end

    newparam(:check_by_ping) do
      defaultto('none')
      validate do |val|
        if val == 'none' or val == 'gateway'
          true
        elsif not val =~ /^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$/
          fail("Invalid IP address: '#{val}'")
        end
      end
    end

    newparam(:check_by_ping_timeout) do
      defaultto(30)
    end

    newparam(:wait_carrier_after_ifup) do
      desc "Enable carrier waiting after interface up. Affect only phys.interfaces."
      newvalues(true, false)
      defaultto(true)
    end

    newparam(:wait_carrier_after_ifup_timeout) do
      desc "Timeout for carrier waiting after interface up."
      defaultto(120)
      validate do |val|
        if val.to_i() >= 0
          true
        else
          fail("Timeout must be a positive integer, not '#{val}'.")
        end
      end
      munge do |val|
        val.to_i()
      end
    end

    def refresh
      provider.restart()
    end

    # autorequire(:l2_bridge) do
    #   [self[:bridge]]
    # end
end
# vim: set ts=2 sw=2 et :