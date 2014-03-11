
Puppet::Type.newtype(:zabbix_hostgroup) do
  desc <<-EOT
    Manage a host group in Zabbix
  EOT

  ensurable do
    defaultvalues
    defaultto :present
  end

  newparam(:name, :namevar => true) do
    desc 'Name of the host group.'
    newvalues(/.+/)
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
