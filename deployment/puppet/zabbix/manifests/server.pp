class zabbix::server {

  anchor { 'zabbix_server_install_start': } ->
  class { 'zabbix::server::install': } ->
  anchor { 'zabbix_server_install_end': }

  anchor { 'zabbix_server_config_start': } ->
  class { 'zabbix::server::config': } ->
  anchor { 'zabbix_server_config_end': }

  Anchor['zabbix_server_install_end'] ->
  Anchor['zabbix_server_config_start']

}
