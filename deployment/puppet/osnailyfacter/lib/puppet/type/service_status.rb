Puppet::Type.newtype(:service_status) do
  desc  'Wait for custom service to become online'

  newparam(:name) do
    desc 'The name of custom service to monitor'
    isnamevar
  end

  newproperty(:ensure) do
    desc 'Expected custom service status'
    newvalues :online, :offline
    defaultto :online
  end

  newparam(:check_cmd) do
    desc 'Command to check status'
  end

  newparam(:exitcode) do
    desc 'Supposed exitcode for check_cmd'
    newvalues(/\d+/)
    defaultto 0
    munge do |n|
      n.to_i
    end
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
end
