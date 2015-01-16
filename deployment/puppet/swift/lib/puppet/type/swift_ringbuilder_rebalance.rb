Puppet::Type.newtype(:swift_ringbuilder_rebalance) do
  desc = "Runs swift-ringbuilder-rabalnce until ring balance equals to the expected value or number of retries reached"

  newparam(:name, :namevar => true) do
    desc "Name of the ring"
    validate do |value|
      raise(Puppet::Error, "invalid name #{value}, should be on of account/object/container") unless ['account', 'object', 'container'].include?(value)
    end
  end

  newparam(:tries) do
    desc "Number of rebalance tries"
    newvalues(/\d+/)
    defaultto 5
    munge do |value|
      value.to_i
    end
    validate do |value|
      unless value.to_i >= 1
        raise ArgumentError, "should be >= 1"
      end
    end
  end

  newparam(:try_sleep) do
    desc "Delay between rebalance retries"
    newvalues(/\d+/)
    defaultto 1
    munge do |value|
      value.to_i
    end
    validate do |value|
      unless value.to_i >= 1
        raise ArgumentError, "should be >= 1"
      end
    end
  end

  newparam(:user) do
    desc "The user to run the command as."
    validate do |user|
      raise ArgumentError, "Only root can execute commands as other users" unless Puppet.features.root?
    end
  end

  newparam(:timeout) do
    desc "The maximum time the command should take.  If the command takes
      longer than the timeout, the command is considered to have failed
      and will be stopped. The timeout is specified in seconds. The default
      timeout is 300 seconds and you can set it to 0 to disable the timeout."

    munge do |value|
      value = value.shift if value.is_a?(Array)
      begin
        value = Float(value)
      rescue ArgumentError
        raise ArgumentError, "The timeout must be a number."
      end
      [value, 0.0].max
    end

    defaultto 300
  end

  newproperty(:balance) do
    desc "Expected ring balance"
    newvalues(/\d+(?:\.\d+)?/)
    defaultto 0
    munge do |value|
      value.to_f
    end
  end

  autorequire(:user) do
    # Autorequire users if they are specified by name
    if user = self[:user] and user !~ /^\d+$/
      user
    end
  end

end
