Puppet::Type.type(:zabbix_template_link).provide(:ruby) do
  confine :feature => :zabbixapi
  
  $LOAD_PATH.unshift("#{File.dirname(__FILE__)}/../../../../lib/ruby/")
  require "zabbix"
  require "pp"


  def exists?
    extend Zabbix
    zbx.templates.get_ids_by_host(
      :hostids => [get_id(resource[:host], 0)]
    ).include?(zbx.templates.get_id(:host => resource[:template]).to_s)
  end
  
  def create
    extend Zabbix
    zbx.templates.mass_add(
      :hosts_id => [get_id(resource[:host], 0)],
      :templates_id => [zbx.templates.get_id(:host => resource[:template])]
    )
  end
  
  def destroy
    extend Zabbix
    zbx.templates.mass_remove(
      :hosts_id => [get_id(resource[:host], 0)],
      :templates_id => [zbx.templates.get_id(:host => resource[:template])]
    )
  end
end
