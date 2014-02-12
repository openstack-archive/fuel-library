Puppet::Type.newtype(:zabbix_api) do

  desc <<-EOT
    Install a zabbix template to a server from a given xml.

    Example:
    
        zabbix{ 'Template_App_Puppet':
          ensure => $present,
        }
    
  EOT

  ensurable do
    defaultvalues
    defaultto :present
  end

  newparam(:name, :namevar => true) do
    desc 'An arbitrary name used as the identity of the resource.'
  end
  
  newparam(:type) do
    desc 'A type to manage, like template, item, host, ...'
  end
  
  newparam(:server) do
    desc 'URL to zabbix frontend'
  end
  
  newparam(:proxy_host) do
    desc 'proxy host if needed'
  end
  
  newparam(:proxy_password) do
    desc 'password to the proxy'
  end
  
  newparam(:user) do
    desc 'zabbix user'
  end
  
  newparam(:password) do
    desc 'zabbix users password'
  end
 
  newparam(:http_user) do
    desc 'zabbix http basic auth user'
  end
  
  newparam(:http_password) do
    desc 'zabbix http basic auth password'
  end
  
  newparam(:host) do
    desc 'host to operate on in cases like items'
  end
  
  newparam(:hostgroup) do
    desc 'hostgroup to put template into'
    defaultto "Templates"
  end
  
  newparam(:description) do
    desc 'description for new items'
  end
  newparam(:application) do
    desc 'application for items'
    defaultto []
  end
  
  newparam(:trigger_type) do
    desc 'type of trigger'
    defaultto '0'
  end
  newparam(:trigger_status) do
    desc 'status of trigger'
    defaultto '0'
  end

  validate do
    unless self[:name] and self[:type]
      raise(Puppet::Error, "zabbix_template: Both name and type are required attributes")
    end
    unless self[:server] and self[:user] and self[:password]
      raise(Puppet::Error, "zabbix_template: server configuration is required")
    end
    unless self[:host] and self[:description] or self[:type] != 'item'
      raise(Puppet::Error, "zabbix_template: items need a host and description")
    end

  end
end
