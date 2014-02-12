Puppet::Type.type(:zabbix_template_item).provide(:ruby, :parent => Puppet::Type.type(:zabbix_item).provider(:ruby)) do
end
