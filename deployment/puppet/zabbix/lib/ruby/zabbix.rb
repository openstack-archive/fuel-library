require "puppet"

# mixin for generic zabbix api stuff
module Zabbix
  ID_BOTH = 0
  ID_HOST = 1
  ID_TEMPLATE = 2

  # initialy load config and setup zabbix api
  def zbx
    return nil if ! Puppet.features.zabbixapi?
    require "zabbixapi" 


    config_file = File.join(File.dirname(Puppet.settings[:config]), "zabbix.api.yaml")
    raise(Puppet::ParseError, "Zabbix report config file #{config_file} not readable") unless File.exist?(config_file)
    config = YAML.load_file(config_file)

    zbx = ZabbixApi.connect(
      :url => config.fetch('zabbix_url', 'http://localhost/zabbix/api_jsonrpc.php'),
      :user => config.fetch('zabbix_user','Admin'),
      :password => config.fetch('zabbix_password', 'zabbix'),
      :http_user => config.fetch('zabbix_http_user', nil),
      :http_password => config.fetch('zabbix_http_password', nil),
      :debug => config.fetch('zabbix_debug', false)
    )
    return zbx
  end

  def get_id(hostname, type=ID_BOTH)
    case type
    when ID_TEMPLATE
      return zbx.hosts.get_id(:host => hostname)
    when ID_HOST
      return zbx.templates.get_id(:host => hostname) 
    else
      return get_template_or_host_id(hostname)
    end
  end

  def get_template_or_host_id(hostname)
      result = zbx.query(
          :method => "host.get",
          :params => {
              :templated_hosts => 1,
              :filter => {
                  :host => hostname  
              },
              :output => "extend"
          }
      )
      id = nil
      result.each { |item| id = item["hostid"].to_i if item["host"] == hostname }
      id
  end
end
