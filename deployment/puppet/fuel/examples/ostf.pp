notice('MODULAR: ostf.pp')

Exec  {path => '/usr/bin:/bin:/usr/sbin:/sbin'}

$fuel_settings = parseyaml($astute_settings_yaml)

class { "fuel::ostf":
  dbname             => $::fuel_settings['postgres']['ostf_dbname'],
  dbuser             => $::fuel_settings['postgres']['ostf_user'],
  dbpass             => $::fuel_settings['postgres']['ostf_password'],
  dbhost             => $::fuel_settings['ADMIN_NETWORK']['ipaddress'],
  nailgun_host       => $::fuel_settings['ADMIN_NETWORK']['ipaddress'],
  host               => "0.0.0.0",
  keystone_host      => $::fuel_settings['ADMIN_NETWORK']['ipaddress'],
  keystone_ostf_user => $::fuel_settings['keystone']['ostf_user'],
  keystone_ostf_pass => $::fuel_settings['keystone']['ostf_password'],
}

fuel::systemd {['ostf']:
  require => Class["fuel::ostf"],
}
