
Puppet::Type.newtype(:zabbix_template) do
  desc <<-EOT
    Manage a template in Zabbix
  EOT

  ensurable do
    defaultvalues
    defaultto :present
  end

  newparam(:name, :namevar => true) do
    desc 'Template name.'
  end
  
  newparam(:group) do
    desc 'Template group'
    defaultto 'Templates'
  end
  
end