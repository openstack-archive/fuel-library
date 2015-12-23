class docker (
  $release,
  $package_ensure      = "latest",
  $admin_ipaddress     = $::fuel_settings['ADMIN_NETWORK']['ipaddress'],
  $limit               = "102400",
  $docker_service      = "docker",
  $docker_engine       = "native",
  $docker_volume_group = "docker",
  $dependent_dirs      = [
    "/var/log/docker-logs",
    "/var/log/docker-logs/remote",
    "/var/log/docker-logs/audit",
    "/var/log/docker-logs/cobbler",
    "/var/log/docker-logs/ConsoleKit",
    "/var/log/docker-logs/coredump",
    "/var/log/docker-logs/httpd",
    "/var/log/docker-logs/nailgun",
    "/var/log/docker-logs/naily",
    "/var/log/docker-logs/nginx",
    "/var/log/docker-logs/ntpstats",
    "/var/log/docker-logs/puppet",
    "/var/log/docker-logs/rabbitmq",
    "/var/log/docker-logs/supervisor",
    "/var/lib/fuel",
    "/var/lib/fuel/keys",
    "/var/lib/fuel/ibp",
    "/var/lib/fuel/container_data",
    "/var/lib/fuel/container_data/${release}",
    "/var/lib/fuel/container_data/${release}/cobbler",
    "/var/lib/fuel/container_data/${release}/postgres",
  ],
  $config_dir = "/etc/dockerctl",
) {

  if $::osfamily == 'RedHat' {
    case $operatingsystemmajrelease {
      '6':     { $docker_package = 'docker-io' }
      '7':     { $docker_package = 'docker' }
      default: { $docker_package = 'docker' }
    }
  }

  package { "${docker_package}":
    ensure => $package_ensure,
  }

  service { "${docker_service}":
    enable     => true,
    ensure     => running,
    hasrestart => true,
    require    => Package["${docker_package}"],
    before     => Class['docker::build'],
  }

  file { '/etc/sysconfig/docker-storage-setup':
    content => template('docker/storage-setup.erb'),
    owner   => 'root',
    group   => 'root',
    mode    => 0644,
    notify  => Service['docker'],
  }

  file { "${dependent_dirs}":
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
    before => Class['docker::build'],
  }

  exec { 'wait for docker-to-become-ready':
    tries     => 10,
    try_sleep => 3,
    command   => 'docker ps 1>/dev/null',
    path      => '/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin',
    require   => Service["${docker_service}"],
    before    => Class['docker::build'],
  }

  $dockerct_config = file("${config_dir}/config")
  $containers_key  = 'CONTAINER_SEQUENCE'
  $containers_line = grep(split($dockerct_config, '\n'), $containers_key)
  $containers      = split(regsubst($containers_line[0], "^${containers_key}=\"(.*)\"", '\1'), '\s')

  class { 'docker::build':
    containers => $containers,
    require    => [
                   File[$dependent_dirs],
                   Service[$docker_service],
                   Exec['wait for docker-to-become-ready'],
                  ],
    before     => Notify['build docker containers notice'],
  }

  # WARNING: please don't remove this! notice used as an anchor in the external
  #          log parsers, for example in the VirtualBox scripts.
  notify { 'build docker containers notice':
    message  => 'build docker containers finished.',
    withpath => true,
  }

}
