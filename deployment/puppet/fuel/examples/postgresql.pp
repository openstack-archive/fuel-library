notice('MODULAR: postgresql.pp')

$fuel_settings = parseyaml($astute_settings_yaml)

class { "fuel::postgresql":
  nailgun_db_name      => $::fuel_settings['postgres']['nailgun_dbname'],
  nailgun_db_user      => $::fuel_settings['postgres']['nailgun_user'],
  nailgun_db_password  => $::fuel_settings['postgres']['nailgun_password'],

  keystone_db_name     => $::fuel_settings['postgres']['keystone_dbname'],
  keystone_db_user     => $::fuel_settings['postgres']['keystone_user'],
  keystone_db_password => $::fuel_settings['postgres']['keystone_password'],

  ostf_db_name         => $::fuel_settings['postgres']['ostf_dbname'],
  ostf_db_user         => $::fuel_settings['postgres']['ostf_user'],
  ostf_db_password     => $::fuel_settings['postgres']['ostf_password'],
}
