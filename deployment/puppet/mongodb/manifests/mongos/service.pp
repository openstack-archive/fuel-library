# PRIVATE CLASS: do not call directly
class mongodb::mongos::service (
  $service_name     = $mongodb::mongos::service_name,
  $service_enable   = $mongodb::mongos::service_enable,
  $service_ensure   = $mongodb::mongos::service_ensure,
  $service_status   = $mongodb::mongos::service_status,
  $service_provider = $mongodb::mongos::service_provider,
) {

  $service_ensure_real = $service_ensure ? {
    absent  => false,
    purged  => false,
    stopped => false,
    default => true
  }

  if $::osfamily == 'RedHat' {
    file { '/etc/sysconfig/mongos' :
      ensure  => present,
      owner   => 'root',
      group   => 'root',
      mode    => '0755',
      content => 'OPTIONS="--quiet -f /etc/mongos.conf"',
      before  => Service['mongos'],
    }
  }

  file { '/etc/init.d/mongos' :
    ensure  => present,
    content => template("mongodb/mongos/${::osfamily}/mongos.erb"),
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    before  => Service['mongos'],
  }

  service { 'mongos':
    ensure    => $service_ensure_real,
    name      => $service_name,
    enable    => $service_enable,
    provider  => $service_provider,
    hasstatus => true,
    status    => $service_status,
  }

}
