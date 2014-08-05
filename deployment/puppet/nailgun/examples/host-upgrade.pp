$fuel_settings = parseyaml($astute_settings_yaml)
$fuel_version = parseyaml($fuel_version_yaml)

if is_hash($::fuel_version) and $::fuel_version['VERSION'] and
$::fuel_version['VERSION']['production'] {
    $production = $::fuel_version['VERSION']['production']
}
else {
    $production = 'prod'
}

Class['nailgun::packages'] ->
Class['docker::dockerctl'] ->
Class['nailgun::client']

class { 'nailgun::packages': }

class { "docker::dockerctl":
  release         => $::fuel_version['VERSION']['release'],
  production      => $production,
  admin_ipaddress => $::fuel_settings['ADMIN_NETWORK']['ipaddress'],
}

class { "nailgun::client":
  server        => $::fuel_settings['ADMIN_NETWORK']['ipaddress'],
  keystone_user => $::fuel_settings['FUEL_ACCESS']['user'],
  keystone_pass => $::fuel_settings['FUEL_ACCESS']['password'],
}

