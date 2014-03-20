class zabbix {
  $enabled  = ! empty(get_server_by_role($::fuel_settings['nodes'], 'zabbix-server'))
  if has_key($::fuel_settings, 'zabbix') and $enabled {
    include zabbix::params
    if $::zabbix::params::server {
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
