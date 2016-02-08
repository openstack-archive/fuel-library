notice('MODULAR: client.pp')

$fuel_settings = parseyaml($astute_settings_yaml)

class { "fuel::nailgun::client":
  server_address     => $::fuel_settings['ADMIN_NETWORK']['ipaddress'],
  keystone_user      => $::fuel_settings['FUEL_ACCESS']['user'],
  keystone_password  => $::fuel_settings['FUEL_ACCESS']['password'],
  # Keystone tenant name cannot be configured in Fuel Menu yet
  keystone_tenant    => 'admin',
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
