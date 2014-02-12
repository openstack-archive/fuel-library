define zabbix::serverconfig (
  $ip = $::zabbix::params::server_ip,
) {

  include zabbix::params

  file { "${zabbix::params::agent_include_path}/server.conf": 
      content => template('zabbix/zabbix_agent_server_include.conf.erb')
  }

}
