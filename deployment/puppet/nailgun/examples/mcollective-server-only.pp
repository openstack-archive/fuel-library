$fuel_settings = parseyaml($astute_settings_yaml)

$mco_host      = $::fuel_settings['ADMIN_NETWORK']['ipaddress']
$mco_port      = '61613'
$mco_pskey     = 'unset'
$mco_vhost     = 'mcollective'
$mco_user      = $::fuel_settings['mcollective']['user']
$mco_password  = $::fuel_settings['mcollective']['password']
$mco_connector = 'rabbitmq'

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

class { '::mcollective':
  connector       => 'rabbitmq',
  server_loglevel => 'debug',
  psk             => $mco_password,
}

create_resource(mcollective::server::setting, $mco_settings)

class { 'nailgun::mcollective': }


Class['::mcollective'] ->
  Mcollective::Server::Setting<||> ->
  Class['nailgun::mcollective']
