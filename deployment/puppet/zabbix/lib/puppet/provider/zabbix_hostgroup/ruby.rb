Puppet::Type.type(:zabbix_hostgroup).provide(:ruby) do
  confine :feature => :zabbixapi

  $LOAD_PATH.unshift("#{File.dirname(__FILE__)}/../../../../lib/ruby/")
  require "zabbix"



  def exists?
    extend Zabbix
    zbx.hostgroups.get_id( 
      :name => resource[:name] 
    ).is_a? Integer
  end
  
  def create
    extend Zabbix
    zbx.hostgroups.create(
      :name => resource[:name]
    )
  end
  
  def destroy
    extend Zabbix
    zbx.query(
      :method => 'hostgroup.delete',
      :params => [
        zbx.hostgroups.get_id( 
          :name => resource[:name] 
        )
      ]
    )
  end
end
