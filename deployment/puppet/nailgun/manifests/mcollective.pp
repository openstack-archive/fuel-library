class nailgun::mcollective(
  $mco_host      = $::nailgun::params::mco_host,
  $mco_port      = $::nailgun::params::mco_port,
  $mco_pskey     = $::nailgun::params::mco_pskey,
  $mco_vhost     = $::nailgun::params::mco_vhost,
  $mco_user      = $::nailgun::params::mco_user,
  $mco_password  = $::nailgun::params::mco_password,
  $mco_connector = $::nailgun::params::mco_connector,
  ) inherits nailgun::params {

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
    }
  }

  if $::osfamily == 'RedHat' {
    case $operatingsystemmajrelease {
      '6': {
        $mco_packages = ['ruby21-rubygem-mcollective-client',
                         'ruby21-nailgun-mcagents']
      }
      '7': {
        $mco_packages = ['mcollective-client', 'nailgun-mcagents']
      }
      default: {
        fail("Unsupported ${::osfamily} release: ${::operatingsystemmajrelease}")
      }
    }
  }

  ensure_packages($mco_packages)

  class { '::mcollective':
    connector        => $mco_connector,
    middleware_hosts => [$mco_host],
    server_loglevel  => 'debug',
    psk              => $mco_pskey,
    manage_packages  => false,
    server           => true,
    client           => true,
    require          => Package[$mco_packages],
  }

  create_resources(mcollective::server::setting, $mco_settings, { 'order' => 90 })

  ensure_packages('fuel-agent')
  ensure_packages('fuel-provisioning-scripts')
  ensure_packages('shotgun')
  ensure_packages('ironic-fa-bootstrap-configs')
  ensure_packages('fuel-bootstrap-image-builder')
}
