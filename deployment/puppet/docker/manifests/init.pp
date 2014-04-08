class docker (
$limit = "102400",
$docker_package = "docker-io",
$docker_service = "docker",
) {

  package {$docker_package:
    ensure => installed,
  }

  service {$docker_service:
    enable => true,
    ensure => running,
    require => Package[$docker_package],
  }
  file { "/etc/sysconfig/docker":
    content => template("docker/settings.erb"),
    owner => 'root',
    group => 'root',
    mode => 0644,
    notify => Service["docker"],
  }
}
