
Puppet::Type.newtype(:zabbix_template_application, :parent => Puppet::Type.type(:zabbix_application)) do
  desc <<-EOT
    Manage a template application in Zabbix
  EOT

  newparam(:host_type) do
    desc <<-EOT
     Type of the host.
     
     Possible values: 
     * 0 - can be both; 
     * 1 - host; 
     * 2 - template; 
    EOT
    defaultto 2
  end
  
end
