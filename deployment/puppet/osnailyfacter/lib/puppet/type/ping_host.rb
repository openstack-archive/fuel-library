Puppet::Type.newtype(:ping_host) do
  desc  'Ping a host until in becomes online'

  newparam(:name) do
    desc 'Hostname or the IP addrress of the host'
    isnamevar
  end

  newproperty(:ensure) do
    desc 'Expected host status'
    newvalues :up, :down
    defaultto :up
  end

  newparam(:count) do
    desc 'How many times try to perform check?'
    newvalues(/\d+/)
    defaultto 30
    munge do |n|
      n.to_i
    end
  end

  newparam(:step) do
    desc 'How many seconds to wait between retries?'
    newvalues(/\d+/)
    defaultto 6
    munge do |n|
      n.to_i
    end
  end

end
