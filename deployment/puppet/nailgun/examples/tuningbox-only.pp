$fuel_settings = parseyaml($astute_settings_yaml)

class { 'nailgun::tuningbox::settings':
  keystone_host       => $::fuel_settings['ADMIN_NETWORK']['ipaddress'],
  keystone_user       => $::fuel_settings['keystone']['tuningbox_user'],
  keystone_pass       => $::fuel_settings['keystone']['tuningbox_password'],
  database_connection => "postgresql://${::fuel_settings['postgres']['tuningbox_user']}:${::fuel_settings['postgres']['tuningbox_password']}@${::fuel_settings['ADMIN_NETWORK']['ipaddress']}/${::fuel_settings['postgres']['tuningbox_dbname']}",
}

class { 'nailgun::tuningbox::syncdb': }

class { 'nailgun::tuningbox::uwsgi': }

class { 'nailgun::tuningbox::systemd': }

Class['nailgun::tuningbox::settings'] ->
Class['nailgun::tuningbox::syncdb'] ->
Class['nailgun::tuningbox::uwsgi'] ->
Class['nailgun::tuningbox::systemd']
