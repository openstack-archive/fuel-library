
Puppet::Type.newtype(:zabbix_mediatype) do
  desc <<-EOT
    Manage a mediatype in Zabbix
  EOT

  ensurable do
    defaultvalues
    defaultto :present
  end
  
  newparam(:description, :namevar => true) do
    desc 'Name.'

    validate do |value|
        unless value =~ /.+/
            raise ArgumentError, "%s is not a valid description" % value
        end
    end
  end

  newparam(:type) do
    desc <<-EOT
      Media type  

      * 0 - Email
      * 1 - External script
      * 2 - SMS
      * 3 - Jabber
      * 100 - EzTexting
    EOT
    defaultto 0
  end
  
  newparam(:status) do
    desc <<-EOT
      Status of the media type

      * 0 - Active
      * 1 - Disabled 
    EOT
    defaultto 0
  end
  
  newparam(:smtp_server) do
    desc 'SMTP server name.'
  end
  
  newparam(:smtp_helo) do
    desc 'HELO value for SMTP server '
  end

  newparam(:smtp_email) do
    desc 'Email address of Zabbix server.'
  end
  
  newparam(:exec_path) do
    desc 'Name of external script.'
  end
  
  newparam(:gsm_modem) do
    desc 'Serial device name of GSM modem'
  end
  
  newparam(:username) do
    desc 'Jabber user name used by Zabbix server '
  end
  
  newparam(:passwd) do
    desc 'Jabber password used by Zabbix server '
  end
end