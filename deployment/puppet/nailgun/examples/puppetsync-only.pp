$fuel_settings = parseyaml($astute_settings_yaml)

if $::fuel_settings['PRODUCTION'] {
    $production = $::fuel_settings['PRODUCTION']
}
else {
    $production = 'docker'
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
