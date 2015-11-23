class nailgun::supervisor(
  $service_enabled = true,
  $nailgun_env,
  $ostf_env,
  $restart_service = true,
  ) {

  file { "/etc/sysconfig/supervisord":
    source => 'puppet:///modules/nailgun/supervisor-sysconfig',
    owner => 'root',
    group => 'root',
    mode => '0644',
  }

  file { "/etc/rc.d/init.d/supervisord":
    source => 'puppet:///modules/nailgun/supervisor-init',
    owner => 'root',
    group => 'root',
    mode => '0755',
    require => [Package["supervisor"],
                File["/etc/sysconfig/supervisord"]],
    notify => Service["supervisord"],
  }

  file { "/etc/supervisord.conf":
    content => template('nailgun/supervisord.conf.base.erb'),
    owner => 'root',
    group => 'root',
    mode => 0644,
    require => Package["supervisor"],
    notify => Service["supervisord"],
  }

  file { '/etc/supervisord.d':
    ensure  => directory,
  }

  file { "/etc/supervisord.d/astute.conf":
    content => template('nailgun/supervisord.conf.astute.erb'),
    owner => 'root',
    group => 'root',
    mode => 0644,
    require => File['/etc/supervisord.d'],
    notify => Service["supervisord"],
  }

  file { "/etc/supervisord.d/nailgun.conf":
    content => template('nailgun/supervisord.conf.nailgun.erb'),
    owner => 'root',
    group => 'root',
    mode => 0644,
    require => File['/etc/supervisord.d'],
    notify => Service["supervisord"],
  }

  file { '/etc/supervisord.d/ostf.conf':
    owner   => 'root',
    group   => 'root',
    mode => 0644,
    content => template('nailgun/supervisor/ostf.conf.erb'),
    require => File['/etc/supervisord.d'],
    notify => Service["supervisord"],
  }

  service { "supervisord":
    ensure => $service_enabled,
    enable => $service_enabled,
    require => [
                Package["supervisor"],
                ],
    hasrestart => true,
    restart => $restart_service ? {
      false   => "/bin/true",
      default => "/usr/bin/supervisorctl stop all; /etc/init.d/supervisord restart",
    },
  }
  Package<| title == 'supervisor' or title == 'nginx' or
    title == 'python-fuelclient'|> ~> Service<| title == 'supervisord'|>
  if !defined(Service['supervisord']) {
    notify{ "Module ${module_name} cannot notify service supervisord on packages update": }
  }

}
