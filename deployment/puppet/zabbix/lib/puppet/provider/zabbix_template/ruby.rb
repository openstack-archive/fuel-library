Puppet::Type.type(:zabbix_template).provide(:ruby) do
  desc "zabbix_template type"
  confine :feature => :zabbixapi
  
  $LOAD_PATH.unshift("#{File.dirname(__FILE__)}/../../../../lib/ruby/")
  require "zabbix"
  require "pp"


  def exists?
    extend Zabbix
    zbx.templates.get_id( 
      :host => resource[:name] 
    ).is_a? Integer
  end
  
  def create
    extend Zabbix
    zbx.templates.create(
      :host => resource[:name], 
      :groups => [ 
        :groupid => zbx.hostgroups.get_or_create( 
          :name => resource[:group] 
        ) 
      ]
    )
  end
  
  def destroy
    extend Zabbix
    zbx.templates.delete( 
      zbx.templates.get_id( 
        :host => resource[:name] 
      ) 
    )
  end
end
