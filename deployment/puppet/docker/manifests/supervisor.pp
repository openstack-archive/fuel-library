class docker::supervisor (
  $release = '6.1',
  $containers = ['astute', 'cobbler', 'keystone', 'mcollective', 'nailgun',
    'ostf', 'postgres', 'rabbitmq', 'rsync', 'rsyslog'],
) {

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
