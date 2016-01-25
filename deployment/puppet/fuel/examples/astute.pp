$fuel_settings = parseyaml($astute_settings_yaml)

$bootstrap_settings = pick($::fuel_settings['BOOTSTRAP'], {})
$bootstrap_flavor   = pick($bootstrap_settings['flavor'], 'centos')

class { 'fuel::astute':
  rabbitmq_host            => $::fuel_settings['ADMIN_NETWORK']['ipaddress'],
  rabbitmq_astute_user     => $::fuel_settings['astute']['user'],
  rabbitmq_astute_password => $::fuel_settings['astute']['password'],
  bootstrap_flavor         => $bootstrap_flavor,
}

fuel::systemd { ['astute']:
  require => Class['fuel::astute']
}
