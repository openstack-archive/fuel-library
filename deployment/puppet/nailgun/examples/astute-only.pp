$fuel_settings = parseyaml($astute_settings_yaml)

$production         = pick($::fuel_settings['PRODUCTION'], 'docker')
$bootstrap_settings = pick($::fuel_settings['BOOTSTRAP'], {})

if $production == 'prod' {
  $env_path  = '/usr'
  $staticdir = '/usr/share/nailgun/static'
} else {
  $env_path  = '/opt/nailgun'
  $staticdir = '/opt/nailgun/share/nailgun/static'
}

$mco_host      = $::fuel_settings['ADMIN_NETWORK']['ipaddress']
$mco_port      = '61613'
$mco_pskey     = 'unset'
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
    value => $mco_password
  },
  'plugin.rabbitmq.heartbeat_interval' => {
    value => '30'
  }
}

if $::osfamily == 'RedHat' {
  case $operatingsystemmajrelease {
    '6': {
      $mco_packages = ['ruby21-rubygem-mcollective-client',
                       'ruby21-nailgun-mcagents']
      $use_systemd  = false
    }
    '7': {
      $mco_packages = ['mcollective-client',
                       'rubygem-mcollective-client',
                       'nailgun-mcagents']
      $use_systemd  = true
    }
    default: {
      fail("Unsupported ${::osfamily} release: ${::operatingsystemmajrelease}")
    }
  }
}

ensure_packages($mco_packages)

Class['docker::container'] ->
Class['nailgun::astute']

class { 'docker::container': }

class { 'nailgun::astute':
  production               => $production,
  rabbitmq_host            => $::fuel_settings['ADMIN_NETWORK']['ipaddress'],
  rabbitmq_astute_user     => $rabbitmq_astute_user,
  rabbitmq_astute_password => $rabbitmq_astute_password,
}

if $use_systemd {
  class { 'nailgun::systemd':
    services   => ['astute'],
    production => $production,
    require    => Class['nailgun::astute']
  }
} else {
  package { 'supervisor': } ->
  class { 'nailgun::supervisor':
    nailgun_env => $env_path,
    ostf_env    => $env_path,
    conf_file   => 'nailgun/supervisord.conf.astute.erb',
    require     => Class['nailgun::astute']
  }
}

class { '::mcollective':
  connector        => 'rabbitmq',
  middleware_hosts => [$mco_hosts],
  psk              => $mco_pskey,
  server           => false,
  client           => true,
  manage_packages  => false,
  require          => Package[$mco_packages],
}

create_resources(mcollective::client::setting, $mco_settings, { 'order' => 90 })
