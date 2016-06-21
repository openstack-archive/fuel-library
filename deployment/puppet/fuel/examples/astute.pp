notice('MODULAR: astute.pp')

$fuel_settings = parseyaml($astute_settings_yaml)
$debug         = pick($::fuel_settings['DEBUG'],false)

$bootstrap_settings = pick($::fuel_settings['BOOTSTRAP'], {})

class { 'fuel::astute':
  debug                    => $debug,
  rabbitmq_host            => $::fuel_settings['ADMIN_NETWORK']['ipaddress'],
  rabbitmq_astute_user     => $::fuel_settings['astute']['user'],
  rabbitmq_astute_password => $::fuel_settings['astute']['password'],
}

fuel::systemd { 'astute':
  require => Class['fuel::astute']
}
