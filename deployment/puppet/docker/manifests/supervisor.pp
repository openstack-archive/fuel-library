class docker::supervisor (
  $release    = false,
  $containers = ['astute', 'cobbler', 'keystone', 'mcollective', 'nailgun',
    'nginx', 'ostf', 'postgres', 'rabbitmq', 'rsync', 'rsyslog'],
) {
  # No empty release allowed
  validate_string($release)

  docker::supervisor::config {$containers: release => $release}
}
