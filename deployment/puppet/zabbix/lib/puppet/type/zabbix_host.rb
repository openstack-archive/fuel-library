
Puppet::Type.newtype(:zabbix_host) do
  desc <<-EOT
    Manage a host in Zabbix
  EOT

  ensurable do
    defaultvalues
    defaultto :present
  end

  newparam(:host, :namevar => true) do
    desc 'Technical name of the host.'
    newvalues(/.+/)
  end

  newparam(:ip) do
    desc <<-EOT
      IP of the host.

      Set this for the default interface to be
      ip based. Use zabbix_host_interface to add
      additional interfaces if you want dns on
      the main agent and an ip for others.
    EOT
    isrequired
    newvalues(/^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$/)
  end

  newparam(:groups) do
    desc 'Host groups to add the host to.'
    isrequired

    validate do |value|
      fail("groups is not an array") unless value.kind_of?(Array) or value.kind_of?(String)
      fail("groups array is empty") if value.empty?
      value.each do |item|
        fail("group name is not a string") unless item.kind_of?(String)
        fail("group name is empty") unless item =~ /.+/
      end
    end
  end

  newparam(:hostname) do
    desc 'Visible name of the host.'
    newvalues(/.+/)
  end

  newparam(:proxy_hostid) do
    desc 'ID of the proxy that is used to monitor the host.'

    validate do |value|
      fail("proxy_hostid is not an integer or integer string") unless value.kind_of?(Integer) or value =~ /[0-9]+/
    end
  end

  newparam(:status) do
    desc <<-EOT
      Status and function of the host.

      Possible values are:
      * 0 - (default) monitored host;
      * 1 - unmonitored host.
    EOT
    newvalues(0, 1)
    defaultto 0
  end

  newparam(:api) do
    desc 'Zabbix api info: endpoint, username, password.'
    isrequired

    validate do |value|
      fail("api is not a hash") unless value.kind_of?(Hash)
      fail("api hash does not contain username") unless value.has_key?("username")
      fail("username is not valid") unless value['username'] =~ /.+/
      fail("api hash does not contain password") unless value.has_key?("password")
      fail("password is not valid") unless value['password'] =~ /.+/
      fail("api hash does not contain endpoint") unless value.has_key?("endpoint")
      fail("endpoint is not valid") unless value['endpoint'] =~ /http(s)?:\/\/.+/
    end
  end

end
