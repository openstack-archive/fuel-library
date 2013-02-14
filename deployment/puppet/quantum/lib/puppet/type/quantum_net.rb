Puppet::Type.newtype(:quantum_net) do

  @doc = "Manage creation/deletion of quantum networks"

  ensurable

  newparam(:name, :namevar => true) do
    desc 'The network name'
  end

  newparam(:tenant) do
    desc "The tenant that the network is associated with" 
    defaultto "admin"
  end

  newparam(:network_type) do
    desc 'Network type'
    defaultto "gre"
  end

  newparam(:physnet) do
    desc 'Private physical network name'
  end

  newparam(:router_ext) do
    # defaultto "False"
  end

  newparam(:shared) do
    # defaultto "False"
  end

  newparam(:segment_id) do
  end

  # validate do
  #   raise(Puppet::Error, 'Label must be set') unless self[:label]
  # end

  # Require the Quantum service to be running
  # autorequire(:service) do
  #   ['quantum-server']
  # end
  autorequire(:package) do
    ['python-quantumclient']
  end

end
