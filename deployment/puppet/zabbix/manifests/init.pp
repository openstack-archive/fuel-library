class zabbix(
  $mysql_server_pkg = $zabbix::params::mysql_server_pkg,
  $mysql_client_pkg = $zabbix::params::mysql_client_pkg,
) inherits zabbix::params {

  if $zabbix_enabled {
    if $server {
      Anchor<| title == 'zabbix_server_end' |> -> Anchor<| title == 'zabbix_config_start' |>
      Anchor<| title == 'zabbix_config_end' |> -> Anchor<| title == 'zabbix_monitoring_start' |>

      anchor { 'zabbix_server_start': } ->
      class { 'zabbix::server': } ->
      anchor { 'zabbix_server_end': }

      anchor { 'zabbix_config_start': } ->
      class { 'zabbix::server::config': } ->
      anchor { 'zabbix_config_end': }

      anchor { 'zabbix_monitoring_start': } ->
      class { 'zabbix::monitoring': } ->
      anchor { 'zabbix_monitoring_end': }
    } else {
      class { 'zabbix::monitoring': }
    }
  }
}
