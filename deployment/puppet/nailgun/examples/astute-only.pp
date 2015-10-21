$fuel_settings = parseyaml($astute_settings_yaml)

$production         = pick($::fuel_settings['PRODUCTION'], 'docker')
$bootstrap_settings = pick($::fuel_settings['BOOTSTRAP'], {})
$bootstrap_flavor   = pick($bootstrap_settings['flavor'], 'centos')

if $production == 'prod' {
  $env_path  = "/usr"
  $staticdir = "/usr/share/nailgun/static"
} else {
  $env_path  = "/opt/nailgun"
  $staticdir = "/opt/nailgun/share/nailgun/static"
}

$mco_host      = $::fuel_settings['ADMIN_NETWORK']['ipaddress']
$mco_vhost     = 'mcollective'
$mco_user      = $::fuel_settings['mcollective']['user']
$mco_password  = $::fuel_settings['mcollective']['password']
$mco_connector = 'rabbitmq'

$rabbitmq_astute_user     = $::fuel_settings['astute']['user']
$rabbitmq_astute_password = $::fuel_settings['astute']['password']

$mco_settings = {
  'ttl' => {
    value => '4294957'
  },
  'direct_addressing' => {
    value => '1'
  },
  'plugin.rabbitmq.vhost' => {
    value => $mco_vhost
  },
  'plugin.rabbitmq.pool.size' => {
    value => '1'
  },
  'plugin.rabbitmq.pool.1.host' => {
    value => $mco_host
  },
  'plugin.rabbitmq.pool.1.port' => {
    value => $mco_port
  },
  'plugin.rabbitmq.pool.1.user' => {
    value => $mco_user
  },
  'plugin.rabbitmq.pool.1.password' => {
    value => $mco_password,
  },
  'plugin.rabbitmq.heartbeat_interval' => {
    value => '30'
  }
}


Class['docker::container'] ->
Class['nailgun::astute'] ->
Class['nailgun::supervisor']

class {'docker::container': }

class {'nailgun::astute':
  production               => $production,
  rabbitmq_host            => $::fuel_settings['ADMIN_NETWORK']['ipaddress'],
  rabbitmq_astute_user     => $rabbitmq_astute_user,
  rabbitmq_astute_password => $rabbitmq_astute_password,
  bootstrap_flavor         => $bootstrap_flavor,
}

package { 'supervisor': } ->
class { "nailgun::supervisor":
  nailgun_env     => $env_path,
  ostf_env        => $env_path,
  conf_file       => "nailgun/supervisord.conf.astute.erb",
}

class { '::mcollective':
  connector => 'rabbitmq',
  psk       => $mco_password,
  server    => false,
  client    => true,
}

create_resource(mcollective::client::setting, $mco_settings)
