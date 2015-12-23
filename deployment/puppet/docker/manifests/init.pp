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
  $dockerctl_config = "/etc/dockerctl/config",
) {

  if $::osfamily == 'RedHat' {
    case $operatingsystemmajrelease {
      '6':     { $docker_package = 'docker-io' }
      '7':     { $docker_package = 'docker' }
      default: { $docker_package = 'docker' }
    }
  }

  package { $docker_package:
    ensure => $package_ensure,
  }

  service { $docker_service:
    enable     => true,
    ensure     => running,
    hasrestart => true,
    require    => Package[$docker_package],
    before     => Anchor['docker-build-start'],
  }

  file { '/etc/sysconfig/docker-storage-setup':
    content => template('docker/storage-setup.erb'),
    owner   => 'root',
    group   => 'root',
    mode    => 0644,
    notify  => Service['docker'],
  }

  file { $dependent_dirs:
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
    before => Anchor['docker-build-start'],
  }

  exec { 'wait for docker-to-become-ready':
    tries     => 10,
    try_sleep => 3,
    command   => 'docker ps 1>/dev/null',
    path      => '/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin',
    require   => Service[$docker_service],
    before    => Anchor['docker-build-start'],
  }

  # this anchor is used to simplify the graph between docker build components
  anchor { 'docker-build-start': }

  $dockerctl_data  = file($dockerctl_config)
  $containers_key  = 'CONTAINER_SEQUENCE'
  $containers_line = grep(split($dockerctl_data, '\n'), "^[\s\t]*${containers_key}")

  if empty($containers_line) {
    fail("dockerctl config should provide the containers list")
  }

  $containers = split(regsubst($containers_line[0], "${containers_key}=\"(.*)\"", '\1'), '\s')

  define docker_build ($container = $title) {

    $cnt_index = inline_template("<%= @containers.index(@container) %>")
    $name_last = inline_template("<%= @containers[-1]%>")

    exec { "container${cnt_index}build":
      command   => "dockerctl --debug build ${container}",
      path      => '/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin',
      timeout   => 7200,
      logoutput => true,
      loglevel  => 'debug',
      unless    => "docker ps -a | egrep -q \"fuel-.*${container}\"",
    }

    exec { "container${cnt_index}check":
      command   => "dockerctl --debug check ${container}",
      path      => '/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin',
      timeout   => 7200,
      logoutput => true,
      loglevel  => 'debug',
      onlyif    => "docker ps -a | egrep -q \"fuel-.*${container}\"",
    }

    if $cnt_index != 0 {
      $cnt_before = inline_template("<%= @containers.index(@container)-1 %>")
      Exec["container${cnt_before}build"] -> Exec["container${cnt_before}check"] ->
      Exec["container${cnt_index}build"] -> Exec["container${cnt_index}check"]
    } else {
      Anchor<| title == 'docker-build-start' |> -> Exec["container0build"]
    }

    if $container == $name_last {
      Exec["container${cnt_index}check"] -> Anchor<| title == 'docker-build-end' |>
    }
  }

  # This creates several new Exec['containter<N><status>'] resources with proper dependency:
  docker_build { $containers:
    containers => $containers
  }

  # WARNING: please don't remove this! notice used as an anchor in the external
  #          log parsers, for example in the VirtualBox scripts.
  anchor { 'docker-build-end': } ->
  notify { 'build docker containers notice':
    message  => 'build docker containers finished.',
    withpath => true,
  }

}
