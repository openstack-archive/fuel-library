notice('MODULAR: mcollective.pp')

$fuel_settings = parseyaml($astute_settings_yaml)

class { 'fuel::mcollective':
  mco_host      => $::fuel_settings['ADMIN_NETWORK']['ipaddress'],
  mco_user      => $::fuel_settings['mcollective']['user'],
  mco_password  => $::fuel_settings['mcollective']['password'],
}
