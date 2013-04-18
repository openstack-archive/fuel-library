Puppet::Type.newtype(:l3_if_downup) do
    @doc = "Down, flush and Up interface"
    desc @doc

    newparam(:interface) do
      isnamevar
      desc "The interface, that will be down, flush and up"
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
      defaultto(120)
    end

    def refresh
      provider.restart
    end

    # autorequire(:l2_ovs_bridge) do
    #   [self[:bridge]]
    # end
end
