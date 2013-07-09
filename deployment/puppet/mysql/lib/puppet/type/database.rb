# This has to be a separate type to enable collecting
Puppet::Type.newtype(:database) do
  @doc = "Manage databases."

  ensurable

  newparam(:name, :namevar=>true) do
    desc "The name of the database."
  end

  newproperty(:charset) do
    desc "The characterset to use for a database"
    defaultto :utf8
    newvalue(/^\S+$/)
  end

  # Connect to remote host
  newproperty(:authorized_user) do
    desc 'Authorization user to remote host'

    defaultto 'root'
  end

  newproperty(:authorized_pass) do
    desc 'Authorization password to remote host'

    defaultto ''

    munge do |value|
      String(value)
    end
  end

  newproperty(:host) do
    desc 'Host for remote authorization'
    validate do |value|
      raise(ArgumentError, "Value: #{value} does not seems like IP") unless value =~ /^(\d{1,3}\.){3}\d{1,3}$/
    end
  end

  newproperty(:port) do
    desc 'Port for remote authorization'

    defaultto '3306'

    validate do |value|
      return if value.instance_of?(FalseClass) and value == false
      port_range = (1025..48999)
      return if value.respond_to?(:to_i) && port_range.include?(value.to_i)
      raise(ArgumentError, "#{value} is incorrect port range #{port_range.min}-#{port_range.max}")
    end

    munge do |value|
      String(value)
    end
  end
end
