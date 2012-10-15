Puppet::Type.newtype(:nova_network) do

  @doc = "Manage creation/deletion of nova networks.  During creation, network
          CIDR and netmask will be calculated automatically"

  ensurable

  # there are concerns about determining uniqiueness of network
  # segments b/c it is actually the combination of network/prefix
  # that determine uniqueness
  newparam(:network, :namevar => true) do
    desc "IPv4 Network (ie, 192.168.1.0/24)"
    newvalues(/^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.0\/[0-9]{1,2}$/)
  end

  newparam(:label) do
    desc "The Nova network label"
    defaultto "novanetwork"
  end

  newparam(:num_networks) do
    desc 'Number of networks to create'
    defaultto(1)
  end

  newparam(:bridge) do
    desc 'bridge to use for flat network'
  end

  newparam(:project) do
    desc 'project that the network is associated with'
  end

  newparam(:gateway) do
  end

  newparam(:dns2) do
  end

  newparam(:vlan_start) do
  end

  newparam(:network_size) do
    defaultto('256')
  end

  validate do
    raise(Puppet::Error, 'Label must be set') unless self[:label]
  end

end
