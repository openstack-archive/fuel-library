class docker::systemd (
  $release = undef,
  $containers_enable = true,
  $restart_timeout = 30,
  $containers = ['astute', 'cobbler', 'keystone', 'mcollective', 'nailgun',
    'nginx', 'ostf', 'postgres', 'rabbitmq', 'rsync', 'rsyslog'],
  $depends = {
    'astute'      => 'rsync',
    'cobbler'     => 'nginx',
    'keystone'    => 'rabbitmq',
    'mcollective' => 'cobbler',
    'nailgun'     => 'rsyslog',
    'nginx'       => 'ostf',
    'ostf'        => 'nailgun',
    'rsync'       => 'keystone',
    'rsyslog'     => 'astute',
    'rabbitmq'    => 'postgres'
  },
) {
  # No empty release allowed
  validate_string($release)

  define docker::systemd::config( $release, $depends, $timeout ) {
    file { "/usr/lib/systemd/system/docker-${title}.service":
      content => template('docker/systemd/template.service.erb'),
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      ensure  => file
    }
    ->
    # Not "service" because containers already running by dockerctl
    exec { "Enable ${title} container":
      command => "/bin/systemctl enable docker-${title}.service"
    }
  }

  docker::systemd::config {$containers:
                            release => $release,
                            depends => $depends,
                            timeout => $restart_timeout}
  ->
  exec { "Reload systemd":
    command => '/bin/systemctl daemon-reload'
  }
}

