class nailgun::supervisor(
  $service_enabled = true,
  $nailgun_env,
  $ostf_env,
  $conf_file = "nailgun/supervisord.conf.erb",
  $restart_service = true,
  $run_as_user = "root",
  ) {

  file { "/etc/sysconfig/supervisord":
    source => 'puppet:///modules/nailgun/supervisor-sysconfig',
    owner => $run_as_user,
    group => $run_as_user,
    mode => '0644',
  }

  file { "/etc/rc.d/init.d/supervisord":
    source => 'puppet:///modules/nailgun/supervisor-init',
    owner => $run_as_user,
    group => $run_as_user,
    mode => '0755',
    require => [Package["supervisor"],
                File["/etc/sysconfig/supervisord"]],
    notify => Service["supervisord"],
  }


  file { "/etc/supervisord.conf":
    content => template($conf_file),
    owner => $run_as_user,
    group => $run_as_user,
    mode => 0644,
    require => Package["supervisor"],
    notify => Service["supervisord"],
  }

  file { "/var/log/supervisor":
    ensure => directory,
    owner  => $run_as_user,
    group  => $run_as_user,
  } ->

  file { "/var/run/supervisor":
    ensure => directory,
    owner  => $run_as_user,
    group  => $run_as_user,
  } ->

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
