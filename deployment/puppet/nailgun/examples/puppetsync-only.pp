$fuel_settings = parseyaml($astute_settings_yaml)
$fuel_version = parseyaml($fuel_version_yaml)

if is_hash($::fuel_version) and $::fuel_version['VERSION'] and
$::fuel_version['VERSION']['production'] {
    $production = $::fuel_version['VERSION']['production']
}
else {
    $production = 'prod'
}

case $production {
  /docker/: {
    $puppet_folder = "/puppet"
  }
  "prod": {
    $puppet_folder = "/etc/puppet"
  }
  default: {
    fail("Unsupported production mode $production")
  }
}

# this replaces removed postgresql version fact
$postgres_default_version = '8.4'


node default {

  Exec  {path => '/usr/bin:/bin:/usr/sbin:/sbin'}
  class { "nailgun::puppetsync":
    puppet_folder => $puppet_folder,
  }

}
