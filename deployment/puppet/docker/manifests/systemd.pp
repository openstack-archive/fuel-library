class docker::systemd (
  $release = undef,
  $containers_enable = true,
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

  define docker::systemd::config( $release, $depends ) {
    file { "/usr/lib/systemd/system/docker-${title}.service":
      content => template('docker/systemd/template.service.erb'),
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      ensure  => file
    }
		->
		service { "docker-${title}":
			ensure  => $containers_enable,
			enable  => $containers_enable,
		}
  }

  docker::systemd::config {$containers: release => $release, depends => $depends}
	->
  exec { "Reload systemd":
    command => '/bin/systemctl daemon-reload'
  }
}

