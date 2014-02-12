
Puppet::Type.newtype(:zabbix_host) do
  desc <<-EOT
    Manage a host in Zabbix

    Create a host in zabbix with a default main
    interface styled after plain agent interface
    based monitoring.
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

  newparam(:ipmi_authtype) do
    desc <<-EOT
      IPMI authentication algorithm.
    
      Possible values are:
      * -1 - (default) default;
      * 0 - none;
      * 1 - MD2;
      * 2 - MD5
      * 4 - straight;
      * 5 - OEM;
      * 6 - RMCP+. 
    EOT
    defaultto -1
  end
  
  newparam(:ipmi_password) do
    desc 'IPMI password.'
  end
  
  newparam(:ipmi_privilege) do
    desc <<-EOT
      IPMI privilege level.
    
      Possible values are:
      * 1 - callback;
      * 2 - (default) user;
      * 3 - operator;
      * 4 - admin;
      * 5 - OEM. 
    EOT
    defaultto 2
  end
  
  newparam(:ipmi_username) do
    desc 'IPMI username.'
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
  
end