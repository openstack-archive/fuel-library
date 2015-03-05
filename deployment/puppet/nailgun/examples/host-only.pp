$fuel_settings = parseyaml($astute_settings_yaml)
$fuel_version = parseyaml($fuel_version_yaml)

if is_hash($::fuel_version) and $::fuel_version['VERSION'] and
$::fuel_version['VERSION']['production'] {
    $production = $::fuel_version['VERSION']['production']
}
else {
    $production = 'prod'
}

$ntp_servers = [$::fuel_settings['NTP1'], $::fuel_settings['NTP2'],
                $::fuel_settings['NTP3']]

Class['nailgun::packages'] ->
Class['nailgun::client'] ->
Class['nailgun::host'] ->
Class['docker::dockerctl'] ->
Class['docker'] ->
Class['openstack::logrotate'] ->
Class['nailgun::supervisor'] ->
Class['monit']

class { 'nailgun::packages': }

class { 'osnailyfacter::atop': }

class { 'nailgun::host':
  production    => $production,
  cobbler_host  => $::fuel_settings['ADMIN_NETWORK']['ipaddress'],
  nailgun_group => $nailgun_group,
  nailgun_user  => $nailgun_user,
  dns_domain    => $::fuel_settings['DNS_DOMAIN'],
  dns_search    => $::fuel_settings['DNS_SEARCH'],

}

class { "openstack::clocksync":
  ntp_servers     => $ntp_servers,
  config_template => "ntp/ntp.conf.erb",
}

class { "docker::dockerctl":
  release         => $::fuel_version['VERSION']['release'],
  production      => $production,
  admin_ipaddress => $::fuel_settings['ADMIN_NETWORK']['ipaddress'],
}

class { "docker":
  docker_engine => 'lxc',
  release => $::fuel_version['VERSION']['release'],
}

class {'openstack::logrotate':
  role           => 'server',
  rotation       => 'weekly',
  keep           => '4',
  limitsize      => '100M',
}

class { "nailgun::client":
  server        => $::fuel_settings['ADMIN_NETWORK']['ipaddress'],
  keystone_user => $::fuel_settings['FUEL_ACCESS']['user'],
  keystone_pass => $::fuel_settings['FUEL_ACCESS']['password'],
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

exec {'sync_deployment_tasks':
  command   => 'fuel rel --sync-deployment-tasks --dir /etc/puppet/',
  path      => '/usr/bin',
  tries     => 12,
  try_sleep => 10,
  require   => Class['nailgun::supervisor']
}

class { "monit": }

# Free disk space monitoring
file { '/usr/bin/fuel_notify.py':
  source  => 'puppet:///modules/nailgun/fuel_notify.py',
  owner   => 'root',
  group   => 'root',
  mode    => '0755',
}

file { "${::monit::params::included}/free-space.conf":
  source  => 'puppet:///modules/nailgun/monit-free-space.conf',
  owner   => 'root',
  group   => 'root',
  mode    => '0644',
  require => Class['monit'],
  notify  => Service['monit'],
}

$monitord_user = $::fuel_settings['keystone']['monitord_user']
$monitord_password = $::fuel_settings['keystone']['monitord_password']
$monitord_tenant = 'services'

file { '/etc/fuel/free_disk_check.yaml':
  content => template("nailgun/free_disk_check.yaml.erb"),
  owner   => 'root',
  group   => 'root',
  mode    => '0755',
}
