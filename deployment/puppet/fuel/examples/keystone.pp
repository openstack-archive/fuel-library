notice('MODULAR: keystone.pp')

$fuel_settings = parseyaml($astute_settings_yaml)

class { 'fuel::keystone':
  admin_token       => $::fuel_settings['keystone']['admin_token'],
  token_expiration  => pick($::fuel_settings['keystone']['token_expiration'], 21600),

  host              => $::fuel_settings['ADMIN_NETWORK']['ipaddress'],
  db_host           => $::fuel_settings['ADMIN_NETWORK']['ipaddress'],
  db_name           => $::fuel_settings['postgres']['keystone_dbname'],
  db_user           => $::fuel_settings['postgres']['keystone_user'],
  db_password       => $::fuel_settings['postgres']['keystone_password'],

  admin_password    => $::fuel_settings['FUEL_ACCESS']['password'],

  monitord_user     => $::fuel_settings['keystone']['monitord_user'],
  monitord_password => $::fuel_settings['keystone']['monitord_password'],

  nailgun_user      => $::fuel_settings['keystone']['nailgun_user'],
  nailgun_password  => $::fuel_settings['keystone']['nailgun_password'],

  ostf_user         => $::fuel_settings['keystone']['ostf_user'],
  ostf_password     => $::fuel_settings['keystone']['ostf_password'],
}
