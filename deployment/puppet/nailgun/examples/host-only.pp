$fuel_settings = parseyaml($astute_settings_yaml)
$fuel_version = parseyaml($fuel_version_yaml)

if is_hash($::fuel_version) and $::fuel_version['VERSION'] and
$::fuel_version['VERSION']['production'] {
    $production = $::fuel_version['VERSION']['production']
}
else {
    $production = 'dev'
}
Class['nailgun::packages'] ->
Class['nailgun::host'] ->
Class['docker::dockerctl'] ->
Class['docker'] ->
Class['openstack::logrotate'] ->
Class['nailgun::supervisor']

class { 'nailgun::packages': }

class { 'nailgun::host':
  production => $production,
  cobbler_host => $::fuel_settings['ADMIN_NETWORK']['ipaddress'],
  nailgun_group => $nailgun_group,
  nailgun_user => $nailgun_user,
}

class { "openstack::clocksync":
  ntp_servers     => $ntp_servers,
  config_template => "ntp/ntp.conf.centosserver.erb",
}

class { "docker::dockerctl":
  release    => $::fuel_version['VERSION']['release'],
  production => $production,
}
class { "docker": }

class {'openstack::logrotate':
  role           => 'server',
  rotation       => 'weekly',
  keep           => '4',
  limitsize      => '100M',
}

class { "nailgun::supervisor":
  nailgun_env => false,
  ostf_env    => false,
  require     => File["/etc/supervisord.d/current", "/etc/supervisord.d/${::fuel_version['VERSION']['release']}"],
  conf_file   => "nailgun/supervisord.conf.base.erb",
}

file { "/etc/supervisord.d":
  ensure  => directory,
}

file { "/etc/supervisord.d/${::fuel_version['VERSION']['release']}":
  require => File["/etc/supervisord.d"],
  owner   => root,
  group   => root,
  recurse => true,
  ensure  => directory,
  source  => "puppet:///modules/docker/supervisor",
}

file { "/etc/supervisord.d/current":
  require => File["/etc/supervisord.d/${::fuel_version['VERSION']['release']}"],
  replace => true,
  ensure  => "/etc/supervisord.d/${::fuel_version['VERSION']['release']}",
}

