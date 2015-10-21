$fuel_settings = parseyaml($astute_settings_yaml)

$mco_host      = $::fuel_settings['ADMIN_NETWORK']['ipaddress']
$mco_port      = '61613'
$mco_pskey     = 'unset'
$mco_vhost     = 'mcollective'
$mco_user      = $::fuel_settings['mcollective']['user']
$mco_password  = $::fuel_settings['mcollective']['password']
$mco_connector = 'rabbitmq'

$mco_settings = {
  'identity' => {
    value => 'master'
  },
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

if $::osfamily == 'RedHat' {
  case $operatingsystemmajrelease {
    '6': {
      $mco_packages = ['ruby21-mcollective']
    }
    '7': {
      $mco_packages = ['mcollective']
    }
    default: {
      fail("Unsupported ${::osfamily} release: ${::operatingsystemmajrelease}")
    }
  }
} else {
  fail("Unsupported operating system: ${::osfamily}")
}

ensure_packages($mco_packages)

class { '::mcollective':
  connector        => 'rabbitmq',
  server_loglevel  => 'debug',
  psk              => $mco_pskey,
  manage_packages  => false,
  require          => Package[$mco_packages],
}

create_resources(mcollective::server::setting, $mco_settings, { 'order' => 90 })

class { 'nailgun::mcollective': }

Class['::mcollective'] -> Class['nailgun::mcollective']
