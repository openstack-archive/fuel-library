include cinder::params

$volume_service = $::cinder::params::volume_service

service { $volume_service:
  ensure     => running,
  enable     => true,
  hasstatus  => true,
  hasrestart => true,
}
