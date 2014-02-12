
Puppet::Type.newtype(:zabbix_application) do
  desc <<-EOT
    Manage a application in Zabbix
  EOT

  ensurable do
    defaultvalues
    defaultto :present
  end

  newparam(:name, :namevar => true) do
    desc 'Application name.'
  end
  
  newparam(:host) do
    desc 'Host'
  end
 
  newparam(:host_type) do
    desc <<-EOT
     Type of the host.
     
     Possible values: 
     * 0 - can be both; 
     * 1 - host; 
     * 2 - template; 
    EOT
    defaultto 0
  end
  
end
