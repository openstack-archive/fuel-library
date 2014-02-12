Puppet::Type.type(:zabbix_application).provide(:ruby) do
  desc "zabbix_application type"
  confine :feature => :zabbixapi

  $LOAD_PATH.unshift("#{File.dirname(__FILE__)}/../../../../lib/ruby/")
  require "zabbix"
  require "pp"

  def exists?
    extend Zabbix
    return (zbx.applications.get_id(
      :name => resource[:name]
    ).is_a? Integer)
  end
  
  def create
    extend Zabbix
    zbx.applications.create(
      :name => resource[:name], 
      :hostid => get_id(resource[:host], resource[:host_type])
    )
  end
  
  def destroy
    extend Zabbix
    zbx.applications.delete( zbx.applications.get_id( :name => resource[:name] ) )
  end
end
