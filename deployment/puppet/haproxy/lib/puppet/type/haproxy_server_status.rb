Puppet::Type.newtype(:haproxy_server_status) do
  desc  'Wait for HAProxy backend to become online'

  newparam(:name) do
    desc 'The name of HAProxy backend to monitor'
    validate do |value|
      service_name = value.split('/')[0]
      server_name = value.split('/')[1]
      if not service_name or  not server_name
        raise ArgumentError, 'haproxy backend server should be a pair of "<service>/<server>" names, e.g. "database/foo"'
      end
    end
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
    newvalues :up, :down, :present, :absent, :maintenance
    munge do |val|
      val.downcase.to_sym
    end
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

  newparam(:control_socket) do
    desc 'Haproxy control socket to '
    defaultto '/var/lib/haproxy/stats'
  end

  def validate
    unless self[:socket].nil? ^ self[:url].nil?
      raise 'You should give either url or socket to get HAProxy status and not both!'
    end
  end

end
