Puppet::Type.newtype(:firewall) do
    @doc = 'High level iptables management.'

    ensurable do
      defaultto(:present)
      newvalue(:present) do
        provider.create
      end
      newvalue(:absent) do
        provider.destroy
      end
    end
  
    # newproperty(:ensure) do
    #     desc 'Is specified port allowed or denied.'

    #     newvalue(:allow) do
    #         provider.allow
    #     end

    #     newvalue(:deny) do
    #         provider.deny
    #     end

    #     defaultto :deny
    # end

    newparam(:name, :isnamevar => true) do
        desc 'Network service name.'
    end

    # newparam(:port) do
    #     desc '<port>:<protocol>'
    # end
    # newparam(:proto) do
    #     desc 'Network protocol name'
    # end

end
