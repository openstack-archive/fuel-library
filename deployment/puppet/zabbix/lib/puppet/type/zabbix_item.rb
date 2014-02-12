
Puppet::Type.newtype(:zabbix_item) do
  desc <<-EOT
    Manage a item in Zabbix
  EOT

  ensurable do
    defaultvalues
    defaultto :present
  end
  
  newparam(:applications) do
    desc 'Array of applications to add the item to.'
    defaultto []
  end

  newparam(:delay) do
    desc 'Update interval of the item in seconds.'
    defaultto 60
  end
  
  newparam(:host) do
    desc 'ID of the host or template that the item belongs to.'
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
  
  newparam(:interface) do
    desc 'ID of the item\'s host interface.'
    defaultto 0
  end
  
  newparam(:key) do
    desc 'Item key.'
  end
  
  newparam(:name, :namevar => true) do
    desc 'Name of the item.'
  end
  
  newparam(:type) do
    desc <<-EOT
     Type of the item.
     
     Possible values: 
     * 0 - Zabbix agent; 
     * 1 - SNMPv1 agent; 
     * 2 - Zabbix trapper; 
     * 3 - simple check; 
     * 4 - SNMPv2 agent; 
     * 5 - Zabbix internal; 
     * 6 - SNMPv3 agent; 
     * 7 - Zabbix agent (active); 
     * 8 - Zabbix aggregate; 
     * 9 - web item; 
     * 10 - external check; 
     * 11 - database monitor; 
     * 12 - IPMI agent; 
     * 13 - SSH agent; 
     * 14 - TELNET agent; 
     * 15 - calculated; 
     * 16 - JMX agent.
    EOT
    defaultto 0
    # @todo support nice strings like from the zabbix apidocs here
  end
  
  newparam(:username) do
    desc <<-EOT
      Username for authentication. Used only by SSH, telnet and JMX items. 
    
      Required by SSH and telnet items.
    EOT
    defaultto ''
  end
  
  newparam(:value_type) do
    desc <<-EOT
      Type of information of the item. 
    
      Possible values: 
      * 0 - numeric float; 
      * 1 - character; 
      * 2 - log; 
      * 3 - numeric unsigned; 
      * 4 - text.
    EOT
    defaultto 0
  end
  
  newparam(:authtype) do
    desc <<-EOT
      SSH authentication method. Used only by SSH agent items. 
    
      Possible values: 
      0 - (default) password; 
      1 - public key.
    EOT
  end

  newparam(:data_type) do
    desc <<-EOT
      Data type of the item. 
    
      Possible values: 
      * 0 - (default) decimal; 
      * 1 - octal; 
      * 2 - hexadecimal; 
      * 3 - boolean.
    EOT
  end

  newparam(:delay_flex) do
    desc <<-EOT
      Flexible intervals as a serialized string. 
    
      Each serialized flexible interval consists of an update interval and a 
      time period separated by a forward slash. Multiple intervals are 
      separated by a colon.
    EOT
  end
  
  newparam(:delta) do
    desc <<-EOT
    Value that will be stored. 
    
    Possible values: 
    * 0 - (default) as is; 
    * 1 - Delta, speed per second; 
    * 2 - Delta, simple change.
    EOT
  end
  
  newparam(:description) do
    desc <<-EOT
      Description of the item.
    EOT
  end
end
