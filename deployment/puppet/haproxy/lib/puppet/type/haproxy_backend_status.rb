Puppet::Type.newtype(:haproxy_backend_status) do
  desc  'Wait for HAProxy backend to become online'

  newparam(:name) do
    desc 'The name of HAProxy backend to monitor'
    isnamevar
  end

  newparam(:url) do
    desc 'Use this url to get CSV status'
  end

  newparam(:socket) do
    desc 'Use this socket to get CSV status'
  end

  newproperty(:ensure) do
    desc 'Expected backend status'
    newvalues :up, :down, :present, :absent
    defaultto :up
  end

  newparam(:count) do
    desc 'How many times try to perform check?'
    newvalues(/\d+/)
    defaultto 100
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

  def validate
    unless self[:socket].nil? ^ self[:url].nil?
      raise 'You should give either url or socket to get HAProxy status and not both!'
    end
  end

end
