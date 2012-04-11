Puppet::Type.newtype(:nova_network) do

  @doc = "Manage creation/deletion of nova networks.  During creation, network
          CIDR and netmask will be calculated automatically"

  ensurable

  # there are concerns about determining uniqiueness of network
  # segments b/c it is actually the combination of network/prefix
  # that determine uniqueness
  newparam(:network, :namevar => true) do
    desc "Network (ie, 192.168.1.0/24)"
    newvalues(/^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.0\/[0-9]{1,2}$/)
  end

  newparam(:label) do
    desc "The Nova network label"
    defaultto "novanetwork"
  end

  newparam(:available_ips) do
    desc "# of available IPs. Must be greater than 4."
    validate do |value|
      if value.to_i < 4
        raise Puppet::Error, "ERROR - nova_network: Parameter available_ips must be an integer greater than 4."
      end
    end
  end

  newparam(:bridge) do
    defaultto 'br100'
  end

end
