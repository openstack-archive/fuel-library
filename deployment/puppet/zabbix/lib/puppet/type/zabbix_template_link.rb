
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
  end
  
  newparam(:host) do
    desc 'Technical name of the host.'
  end
  
  newparam(:template) do
    desc 'Template name to link the host to.'
  end
  
end