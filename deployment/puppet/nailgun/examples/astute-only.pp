$fuel_settings = parseyaml($astute_settings_yaml)
$fuel_version = parseyaml($fuel_version_yaml)

if is_hash($::fuel_version) and $::fuel_version['VERSION'] and
$::fuel_version['VERSION']['production'] {
    $production = $::fuel_version['VERSION']['production']
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
$postgres_default_version = '8.4'

$mco_pskey = "unset"
$mco_vhost = "mcollective"
$mco_user = "mcollective"
$mco_password = "marionette"
$mco_connector = "rabbitmq"

$rabbitmq_astute_user = "naily"
$rabbitmq_astute_password = "naily"


node default {

  Exec  {path => '/usr/bin:/bin:/usr/sbin:/sbin'}

  Class['nailgun::packages'] ->
  Class['nailgun::ostf'] ->
  Class['nailgun::supervisor']

  class { "nailgun::packages": }

  if $::fuel_settings['GEM_SOURCE'] {
    $gem_source = $::fuel_settings['GEM_SOURCE']
  } else {
    $gem_source = "http://${::fuel_settings['ADMIN_NETWORK']['ipaddress']}:8080/gems/"
  }

  class {"nailgun::astute":
    rabbitmq_host            => $::fuel_settings['ADMIN_NETWORK']['ipaddress'],
    rabbitmq_astute_user     => $rabbitmq_astute_user,
    rabbitmq_astute_password => $rabbitmq_astute_password,
    version                  => '0.1.0',
    gem_source               => $gem_source,
  }

  class { "nailgun::supervisor":
    nailgun_env     => $env_path,
    ostf_env        => $env_path,
    conf_file       => "nailgun/supervisord.conf.astute.erb",
  }
}
