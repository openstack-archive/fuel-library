# This has to be a separate type to enable collecting
Puppet::Type.newtype(:database_user) do
  @doc = "Manage a database user. This includes management of users password as well as priveleges"

  ensurable

  newparam(:name, :namevar=>true) do
    desc "The name of the user. This uses the 'username@hostname' or username@hostname."
    validate do |value|
      # https://dev.mysql.com/doc/refman/5.1/en/account-names.html
      # Regex should problably be more like this: /^[`'"]?[^`'"]*[`'"]?@[`'"]?[\w%\.]+[`'"]?$/
      raise(ArgumentError, "Invalid database user #{value}") unless value =~ /[\w-]*@[\w%\.]+/
      username = value.split('@')[0]
      if username.size > 16
        raise ArgumentError, "MySQL usernames are limited to a maximum of 16 characters"
      end
    end
  end

  newproperty(:password_hash) do
    desc "The password hash of the user. Use mysql_password() for creating such a hash."
    newvalue(/\w+/)
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
      port_range = (1025..48999)
      return if value.respond_to?(:to_i) && port_range.include?(value.to_i)
      raise(ArgumentError, "#{value} is incorrect port range #{port_range.min}-#{port_range.max}")
    end

    munge do |value|
      String(value)
    end
  end
end
