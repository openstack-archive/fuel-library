
Puppet::Type.newtype(:zabbix_hostgroup) do
  desc <<-EOT
    Manage a host group in Zabbix
  EOT

  ensurable do
    defaultvalues
    defaultto :present
  end

  newparam(:name, :namevar => true) do
    desc 'Name of the host group.'
  end
end