class zabbix(
  $api_ip,
  $server_ip,
  $db_ip,
  $ports = { server => '10051', backend_server => undef, agent => '10050', backend_agent => undef, api => '80' },
  $primary_controller = false,
  $username = 'admin',
  $password = 'zabbix',
  $db_password = 'zabbix',
) {
  include zabbix::params

  $password_hash = md5($password)
  $api_url = "http://${api_ip}:${ports['api']}${zabbix::params::frontend_base}/api_jsonrpc.php"
  $api_hash = { endpoint => $api_url,
                username => $username,
                password => $password }

  Anchor<| title == 'zabbix_server_end' |> -> Anchor<| title == 'zabbix_config_start' |>

  anchor { 'zabbix_server_start': } ->
  class { 'zabbix::server':
    db_ip               => $db_ip,
    primary_controller  => $primary_controller,
    db_password         => $db_password,
  } ->
  anchor { 'zabbix_server_end': }

  if ($::fuel_settings["deployment_mode"] == "multinode") or
     ($::fuel_settings["role"] == "primary-controller") {
    anchor { 'zabbix_config_start': } ->
    class { 'zabbix::server::config':
      api_hash => $api_hash,
    } ->
    anchor { 'zabbix_config_end': }
  }
}
