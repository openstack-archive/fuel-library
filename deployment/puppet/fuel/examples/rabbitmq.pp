$fuel_settings = parseyaml($astute_settings_yaml)

$thread_pool_calc = min(100,max(12*$physicalprocessorcount,30))

class { 'fuel::rabbitmq':
  astute_user     => $::fuel_settings['astute']['user'],
  astute_password => $::fuel_settings['astute']['password'],
  bind_ip         => $::fuel_settings['ADMIN_NETWORK']['ipaddress'],
  mco_user        => $::fuel_settings['mcollective']['user'],
  mco_password    => $::fuel_settings['mcollective']['password'],
  env_config      => {
    'RABBITMQ_SERVER_ERL_ARGS' => "+K true +A${thread_pool_calc} +P 1048576",
    'ERL_EPMD_ADDRESS'         => $::fuel_settings['ADMIN_NETWORK']['ipaddress'],
    'NODENAME'                 => "rabbit@${::hostname}",
  },
}
