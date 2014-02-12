Puppet::Type.type(:zabbix_host_item).provide(:ruby, :parent => Puppet::Type.type(:zabbix_item).provider(:ruby)) do
end
