notice('MODULAR: client.pp')

$fuel_settings = parseyaml($astute_settings_yaml)

class { 'fuel::nailgun::client':
  server_address    => $::fuel_settings['ADMIN_NETWORK']['ipaddress'],
  keystone_user     => $::fuel_settings['FUEL_ACCESS']['user'],
  keystone_password => $::fuel_settings['FUEL_ACCESS']['password'],
  keystone_tenant   => pick($::fuel_settings['FUEL_ACCESS']['tenant'], 'admin'),
  auth_url          => "http://${::fuel_settings['ADMIN_NETWORK']['ipaddress']}:8000/keystone/v2.0",
}

# This exec needs python-fuelclient to be installed and nailgun running
# Probably this should be moved to a separate task
exec {'sync_deployment_tasks':
  command   => 'fuel rel --sync-deployment-tasks --dir /etc/puppet/',
  path      => '/usr/bin',
  tries     => 12,
  try_sleep => 10,
  require   => Class['fuel::nailgun::client']
}

exec {'upload_default_sequence':
  command   => '/etc/puppet/modules/fuel/files/upload-default-sequence.sh',
  path      => '/usr/bin',
  tries     => 2,
  try_sleep => 10,
  require   => Exec['sync_deployment_tasks']
}
