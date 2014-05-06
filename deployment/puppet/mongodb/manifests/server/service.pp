# PRIVATE CLASS: do not call directly
class mongodb::server::service {
  $ensure           = $mongodb::server::ensure
  $service_name     = $mongodb::server::service_name
  $service_provider = $mongodb::server::service_provider
  $service_status   = $mongodb::server::service_status

  $service_ensure = $ensure ? {
    present => true,
    absent  => false,
    default => $ensure
  }

  service { 'mongodb':
    ensure    => $service_ensure,
    name      => $service_name,
    enable    => $service_ensure,
    provider  => $service_provider,
    hasstatus => true,
    status    => $service_status,
  }

  exec { 'wait_until_mongo_is_up' :
    command     => "/usr/bin/mongo --quiet --eval 'db.getName()'",
    tries       => '100',
    try_sleep   => '3',
    refreshonly => true,
  }

  Service['mongodb'] ~> Exec['wait_until_mongo_is_up']

}
