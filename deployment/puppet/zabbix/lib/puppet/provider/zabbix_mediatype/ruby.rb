Puppet::Type.type(:zabbix_mediatype).provide(:ruby) do
  desc "zabbix mediatype provider"
  confine :feature => :zabbixapi

  $LOAD_PATH.unshift("#{File.dirname(__FILE__)}/../../../../lib/ruby/")
  require "zabbix"

  def exists?
    extend Zabbix
    return (zbx.mediatypes.get_id(
      :description => resource[:name]
    ).is_a? Integer)
  end
  
  def create
    extend Zabbix
    zbx.mediatypes.create(
      :description => resource[:name],
      :type => resource[:type],
      :status => resource[:status],
      :smtp_server => resource[:smtp_server],
      :smtp_helo => resource[:smtp_helo],
      :smtp_email => resource[:smtp_email],
      :exec_path => resource[:exec_path],
      :gsm_modem => resource[:gsm_modem],
      :username => resource[:username],
      :passwd => resource[:passwd]
    )
  end
  
  def destroy
    extend Zabbix
    zbx.mediatypes.delete( zbx.mediatypes.get_id( :description => resource[:name] ) )
  end
end
