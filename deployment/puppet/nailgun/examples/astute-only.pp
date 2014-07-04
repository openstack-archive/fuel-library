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

$mco_host = $::fuel_settings['ADMIN_NETWORK']['ipaddress']
$mco_pskey = "unset"
$mco_vhost = "mcollective"
$mco_user = $::fuel_settings['mcollective']['user']
$mco_password = $::fuel_settings['mcollective']['password']
$mco_connector = "rabbitmq"

$rabbitmq_astute_user = $::fuel_settings['astute']['user']
$rabbitmq_astute_password = $::fuel_settings['astute']['password']


node default {

  Exec  {path => '/usr/bin:/bin:/usr/sbin:/sbin'}

  Class['nailgun::astute'] ->
  Class['nailgun::supervisor']

  class {"nailgun::astute":
    production               => $production,
    rabbitmq_host            => $::fuel_settings['ADMIN_NETWORK']['ipaddress'],
    rabbitmq_astute_user     => $rabbitmq_astute_user,
    rabbitmq_astute_password => $rabbitmq_astute_password,
    version                  => '0.1.0',
  }
  package { "supervisor": } ->
  class { "nailgun::supervisor":
    nailgun_env     => $env_path,
    ostf_env        => $env_path,
    conf_file       => "nailgun/supervisord.conf.astute.erb",
  }
  class { "mcollective::client":
    pskey    => $::mco_pskey,
    vhost    => $::mco_vhost,
    user     => $::mco_user,
    password => $::mco_password,
    host     => $::mco_host,
    stomp    => false,
  }
}
