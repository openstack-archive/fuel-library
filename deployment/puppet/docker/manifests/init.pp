class docker (
$admin_ipaddress = $::fuel_settings['ADMIN_NETWORK']['ipaddress'],
$limit = "102400",
$docker_package = "docker-io",
$docker_service = "docker",
$dependent_dirs = ["/var/log/docker-logs", "/var/log/docker-logs/remote",
  "/var/log/docker-logs/audit", "/var/log/docker-logs/cobbler",
  "/var/log/docker-logs/ConsoleKit", "/var/log/docker-logs/coredump",
  "/var/log/docker-logs/httpd", "/var/log/docker-logs/lxc",
  "/var/log/docker-logs/nailgun", "/var/log/docker-logs/naily",
  "/var/log/docker-logs/nginx", "/var/log/docker-logs/ntpstats",
  "/var/log/docker-logs/puppet", "/var/log/docker-logs/rabbitmq",
  "/var/log/docker-logs/rhsm", "/var/log/docker-logs/supervisor",
  ]
) {

  package {$docker_package:
    ensure => installed,
  }

  service {$docker_service:
    enable => true,
    ensure => running,
    require => Package[$docker_package],
    hasrestart => true,
    restart => "/etc/init.d/docker restart;/usr/bin/dockerctl start all",
    start => "/etc/init.d/docker start;/usr/bin/dockerctl start all",
  }
  file { "/etc/sysconfig/docker":
    content => template("docker/settings.erb"),
    owner => 'root',
    group => 'root',
    mode => 0644,
    notify => Service["docker"],
  }
  file { $dependent_dirs:
    ensure => directory,
    owner => 'root',
    group => 'root',
    mode => '0755',
  }
  exec {'wait for docker-to-become-ready':
    tries     => 10,
    try_sleep => 3,
    command   => 'docker ps 1>/dev/null',
    path      => "/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin",
    require   => [Service[$docker_service]]
  }
  exec {'build docker containers':
    command   => 'dockerctl build all',
    path      => '/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin',
    timeout   => 7200,
    logoutput => true,
    require   => [
                  File[$dependent_dirs],
                  Service[$docker_service],
                  Exec['wait for docker-to-become-ready'],
                  ],
    unless    => 'docker ps -a | grep -q fuel',
  }
}
