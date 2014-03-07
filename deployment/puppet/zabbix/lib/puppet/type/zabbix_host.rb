
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
  end
  
  newparam(:ip) do
    desc <<-EOT
      IP of the host.

      Set this for the default interface to be
      ip based. Use zabbix_host_interface to add
      additional interfaces if you want dns on
      the main agent and an ip for others.
    EOT
  end
  
  newparam(:groups) do
    desc 'Host groups to add the host to.'
  end

  newparam(:hostname) do
    desc 'Visible name of the host.'
  end
  
  newparam(:proxy_hostid) do
    desc 'ID of the proxy that is used to monitor the host.'
  end
  
  newparam(:status) do
    desc <<-EOT
      Status and function of the host.
    
      Possible values are:
      * 0 - (default) monitored host;
      * 1 - unmonitored host. 
    EOT
    defaultto 0
  end
  
  newparam(:api) do
    desc 'Zabbix api info: endpoint, username, password.'
    isrequired
  end

end
