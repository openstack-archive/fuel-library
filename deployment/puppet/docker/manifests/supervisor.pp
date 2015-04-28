class docker::supervisor (
  $release = false,
  $containers = ['astute', 'cobbler', 'keystone', 'mcollective', 'nailgun',
    'nginx', 'ostf', 'postgres', 'rabbitmq', 'rsync', 'rsyslog'],
) {
  # No empty release allowed
  validate_string($release)

  define docker::supervisor::config( $release) {
    file { "/etc/supervisord.d/${release}/${title}.conf":
      content => template('docker/supervisor/base.conf.erb'),
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
    }
  }

  docker::supervisor::config {$containers: release => $release}
}
