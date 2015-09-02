$fuel_settings = parseyaml($astute_settings_yaml)

if $fuel_production {
    $production = $fuel_production
}
else {
    $production = 'prod'
}

if $production == 'prod'{
  $env_path = "/usr"
  $staticdir = "/usr/share/nailgun/static"
} else {
  $env_path = "/opt/nailgun"
  $staticdir = "/opt/nailgun/share/nailgun/static"
}

# this replaces removed postgresql version fact
$postgres_default_version = '9.3'


node default {

  Exec  {path => '/usr/bin:/bin:/usr/sbin:/sbin'}
  class { "nailgun::puppetsync": }

}
