# PRIVATE CLASS: do not call directly
class mongodb::server::service {
  $ensure           = $mongodb::server::service_ensure
  $service_enable   = $mongodb::server::service_enable
  $service_name     = $mongodb::server::service_name
  $service_provider = $mongodb::server::service_provider
  $service_status   = $mongodb::server::service_status
  $bind_ip          = $mongodb::server::bind_ip
  $port             = $mongodb::server::port
  $configsvr        = $mongodb::server::configsvr
  $shardsvr         = $mongodb::server::shardsvr

  if !$port {
    if $configsvr {
      $port_real = 27019
    } elsif $shardsvr {
      $port_real = 27018
    } else {
      $port_real = 27017
    }
  } else {
    $port_real = $port
  }

  $service_ensure = $ensure ? {
    absent  => false,
    purged  => false,
    stopped => false,
    default => true
  }

  service { 'mongodb':
    ensure    => $service_ensure,
    name      => $service_name,
    enable    => $service_enable,
    provider  => $service_provider,
    hasstatus => true,
    status    => $service_status,
  }

  if $service_ensure {
    mongodb_conn_validator { "mongodb":
      server  => $bind_ip,
      port    => $port_real,
      timeout => '240',
      require => Service['mongodb'],
    }
  }
}
