
Puppet::Type.newtype(:zabbix_host_interface) do
  desc <<-EOT
    Manage a host Interface in Zabbix

    Create a new interface for an existing host.

  EOT

  ensurable do
    defaultvalues
    defaultto :present
  end
  
  newparam(:name, :namevar => true) do
    desc 'Technical name of the host interface.'
  end
 
  newparam(:host) do
    desc <<-EOT
      The Hostname.
    EOT
  end
 
  newparam(:ip) do
    desc <<-EOT
      IP of the interface.
    EOT
  end
  
  newparam(:dns) do
    desc 'DNS name of the host. Defaults to the empty string.'
  end

  newparam(:port) do
    desc 'The port number used by the interface. Can contain user macros. Defaults to 10050'
    defaultto 10050
  end

  newparam(:type) do
    desc <<-EOT
      Interface type. 

      Possible values are: 
      * 1 - (default) agent; 
      * 2 - SNMP; 
      * 3 - IPMI; 
      * 4 - JMX. 
    EOT
    defaultto 1
  end

  newparam(:main) do
    desc <<-EOT
      Whether the interface is used as default on the host. Only one interface of some type can be set as default on a host. 

      Possible values are: 
      * 0 - (default) not default; 
      * 1 - default.
    EOT
    defaultto 0
  end

  newparam(:useip) do
    desc <<-EOT
      Whether the connection should be made via IP. 

      Possible values are: 
      * 0 - connect using host DNS name; 
      * 1 - (default) connect using host IP address.
    EOT
    defaultto 1
  end

end
