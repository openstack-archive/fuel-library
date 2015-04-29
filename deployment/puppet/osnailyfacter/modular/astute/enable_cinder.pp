include cinder::params

$volume_package = $::cinder::params::volume_package
$volume_service = $::cinder::params::volume_service

package { $volume_service:
  ensure     => installed,
}

service { $volume_service:
  ensure     => running,
  enable     => true,
  hasstatus  => true,
  hasrestart => true,
}

Package[$volume_service]->Service[$volume_service]
