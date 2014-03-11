
Puppet::Type.newtype(:zabbix_template_link) do
  desc <<-EOT
    Manage a template link in Zabbix
  EOT

  ensurable do
    defaultvalues
    defaultto :present
  end

  newparam(:name, :namevar => true) do
    desc 'Template link name.'
    newvalues(/.+/)
  end

  newparam(:host) do
    desc 'Technical name of the host.'
    newvalues(/.+/)
    isrequired
  end

  newparam(:template) do
    desc 'Template name to link the host to.'
    newvalues(/.+/)
    isrequired
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
