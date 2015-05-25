class sahara::engine (
  $enabled                      = true,
  $rpc_backend                  = undef,
  $amqp_password                = undef,
  $amqp_user                    = 'guest',
  $amqp_host                    = 'localhost',
  $amqp_port                    = '5672',
  $amqp_hosts                   = false,
  $rabbit_virtual_host          = '/',
  $rabbit_ha_queues             = false,
  $service_name                 = $sahara::params::sahara_engine_service_name,
  $package_name                 = $sahara::params::sahara_engine_package_name,
) inherits sahara::params {

  if $enabled {
    $service_ensure = 'running'
  } else {
    $service_ensure = 'stopped'
  }

  package { 'sahara-engine':
    ensure  => 'installed',
    name    => $package_name,
    require => Package['sahara-api'],
  }

  service { 'sahara-engine':
    ensure     => $service_ensure,
    name       => $service_name,
    enable     => $enabled,
    hasstatus  => true,
    hasrestart => true,
    require    => Package['sahara-engine'],
  }

  if $rpc_backend == 'rabbit' {
    class { 'sahara::rpc_backend::rabbitmq':
      rabbit_password      => $amqp_password,
      rabbit_userid        => $amqp_user,
      rabbit_host          => $amqp_host,
      rabbit_port          => $amqp_port,
      rabbit_hosts         => $amqp_hosts,
      rabbit_virtual_host  => $rabbit_virtual_host,
      rabbit_ha_queues     => $rabbit_ha_queues,
    }
  }

  if $rpc_backend == 'qpid' {
    class { 'sahara::rpc_backend::qpid':
      qpid_password  => $amqp_password,
      qpid_username  => $amqp_user,
      qpid_hostname  => $amqp_host,
      qpid_port      => $amqp_port,
      qpid_hosts     => $amqp_hosts,
    }
  }

  Package['sahara-engine'] ~> Service['sahara-engine']
  Sahara_config<||> ~> Service['sahara-engine']
}

