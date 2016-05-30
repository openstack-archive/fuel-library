$fuel_settings = parseyaml($astute_settings_yaml)

# prepare repo with tuning-box package and its dependencies
class { 'nailgun::tuningbox::standalone::repo':}

# pass changed manifests to docker containers and restart it
class { 'nailgun::tuningbox::standalone::containers':
  # keystone data
  keystone_host => $::fuel_settings['ADMIN_NETWORK']['ipaddress'],
  keystone_user => $::fuel_settings['keystone']['tuningbox_user'],
  keystone_pass => $::fuel_settings['keystone']['tuningbox_password'],
  # postgres data
  db_host       => $::fuel_settings['ADMIN_NETWORK']['ipaddress'],
  db_name       => $::fuel_settings['postgres']['tuningbox_dbname'],
  db_user       => $::fuel_settings['postgres']['tuningbox_user'],
  db_pass       => $::fuel_settings['postgres']['tuningbox_password'],
}

Class['nailgun::tuningbox::standalone::repo'] ->
Class['nailgun::tuningbox::standalone::containers']
