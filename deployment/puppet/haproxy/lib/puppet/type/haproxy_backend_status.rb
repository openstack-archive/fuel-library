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

  newparam(:timeout) do
    desc 'How long should we wait for a request to finish?'
    newvalues(/\d+/)
    defaultto 5
    munge do |n|
      n.to_i
    end
  end

  newparam(:ssl_verify_mode) do
    desc 'HTTPS SSL verify mode. Defaults to `default` which means built-in default.'
    newvalues('none', 'peer', 'default')
    defaultto 'default'
    munge do |value|
      value.to_s
    end
  end

  def validate
    unless self[:socket].nil? ^ self[:url].nil?
      raise 'You should give either url or socket to get HAProxy status and not both!'
    end
  end

end
