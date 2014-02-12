Puppet::Type.type(:zabbix_template_application).provide(:ruby, :parent => Puppet::Type.type(:zabbix_application).provider(:ruby)) do
end
