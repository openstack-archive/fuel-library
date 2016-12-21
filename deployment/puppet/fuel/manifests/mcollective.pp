class fuel::mcollective(
  $mco_host            = $::fuel::params::mco_host,
  $mco_port            = $::fuel::params::mco_port,
  $mco_pskey           = $::fuel::params::mco_pskey,
  $mco_vhost           = $::fuel::params::mco_vhost,
  $mco_user            = $::fuel::params::mco_user,
  $mco_password        = $::fuel::params::mco_password,
  $mco_connector       = $::fuel::params::mco_connector,
  $mco_packages_extra  = $::fuel::params::mco_packages_extra,
  ) inherits fuel::params {

  include stdlib

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
    },
    'plugin.rabbitmq.max_hbrlck_fails' => {
      value => '0'
    }
  }

  if $::osfamily == 'RedHat' {
    case $operatingsystemmajrelease {
      '6': {
        $mco_packages = ['ruby21-rubygem-mcollective-client',
                         'ruby21-nailgun-mcagents']
      }
      '7': {
        $mco_packages = ['mcollective-client',
                         'rubygem-mcollective-client',
                         'nailgun-mcagents']
      }
      default: {
        fail("Unsupported ${::osfamily} release: ${::operatingsystemmajrelease}")
      }
    }
  }

  ensure_packages($mco_packages)
  ensure_packages($mco_packages_extra)

  class { '::mcollective':
    connector          => $mco_connector,
    middleware_hosts   => [$mco_host],
    server_loglevel    => 'debug',
    client_loglevel    => 'debug',
    client_logger_type => 'file',
    psk                => $mco_pskey,
    manage_packages    => false,
    server             => true,
    client             => true,
    require            => Package[$mco_packages],
  }

  create_resources(mcollective::server::setting, $mco_settings, { 'order' => 90 })
  $mco_settings['logfile'] = { value => '/var/log/mcollective-client.log'}
  create_resources(mcollective::client::setting, $mco_settings, { 'order' => 90 })

}
