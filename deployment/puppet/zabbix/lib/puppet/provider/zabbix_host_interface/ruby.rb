Puppet::Type.type(:zabbix_host_interface).provide(:ruby) do
  desc "zabbix_host_interface type"
  confine :feature => :zabbixapi
  
  $LOAD_PATH.unshift("#{File.dirname(__FILE__)}/../../../../lib/ruby/")
  require "zabbix"
  require "pp"

  def exists?
    extend Zabbix
    hostid = zbx.hosts.get_id(:host => resource[:host])
    return zbx.query(
      :method => 'hostinterface.exists',
      :params => {
        :hostid => hostid,
        :dns => resource[:dns],
        :ip => resource[:ip]
      }
    )
  end
  
  def create
    extend Zabbix
    hostid = zbx.hosts.get_id(:host => resource[:host])
    zbx.query(
      :method => 'hostinterface.create',
      :params => {
        :hostid => hostid,
        :ip => resource[:ip] == nil ? "" : resource[:ip],
        :dns => resource[:dns] == nil ? "" : resource[:dns],
        :port => resource[:port],
        :type => resource[:type],
        :main => resource[:main],
        :useip => resource[:useip]
      }
    )
  end
  
  def destroy
    extend Zabbix
    hostid = zbx.hosts.get_id(:host => resource[:host])
    return zbx.query(
      :method => 'hostinterface.massremove',
      :params => {
        :hostids => [hostid],
        :interfaces => [
          :ip => resource[:ip] == nil ? "" : resource[:ip],
          :dns => resource[:dns] == nil ? "" : resource[:dns],
          :port => resource[:port]
        ]
      }
    )
  end
end
