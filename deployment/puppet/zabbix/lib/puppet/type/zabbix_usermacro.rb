Puppet::Type.newtype(:zabbix_usermacro) do
  desc <<-EOT
    Manage a macro in Zabbix.
  EOT

  ensurable do
    defaultvalues
    defaultto :present
  end

  newparam(:name, :namevar => true) do
    desc 'namevar'
  end

  newparam(:api) do
    desc 'Zabbix api info: endpoint, username, password.'
    isrequired
  end

  newparam(:macro) do
    desc 'Macro name'
    isrequired
  end

  newproperty(:value) do
    desc 'Macro value'
    isrequired
  end

  newparam(:global) do
    desc <<-EOT
      Macro global flag. If true macro is global.
      If false macro belongs to host/template.
    EOT
    defaultto(:false)
    newvalues(:true, :false)
  end
  
  newparam(:host) do
    desc 'Host'
  end

  validate do
    fail('host should not be provided when global is true') if
    self[:global] == :true and not self[:host].nil?
    fail('host is required when global is false') if
    self[:global] == :false and self[:host].nil?
  end
end

