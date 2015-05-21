# Configuration of Fuel Master node only

$fuel_settings = parseyaml($astute_settings_yaml)
$fuel_version = parseyaml($fuel_version_yaml)

if is_hash($::fuel_version) and $::fuel_version['VERSION'] and
$::fuel_version['VERSION']['production'] {
    $production = $::fuel_version['VERSION']['production']
}
else {
    $production = 'prod'
}

#Purge empty NTP server entries
$ntp_servers = delete([$::fuel_settings['NTP1'], $::fuel_settings['NTP2'],
                      $::fuel_settings['NTP3']], "")

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
  production        => $production,
  cobbler_host      => $::fuel_settings['ADMIN_NETWORK']['ipaddress'],
  nailgun_group     => $nailgun_group,
  nailgun_user      => $nailgun_user,
  dns_domain        => $::fuel_settings['DNS_DOMAIN'],
  dns_search        => $::fuel_settings['DNS_SEARCH'],
  repo_root         => "/var/www/nailgun/${::fuel_version['VERSION']['openstack_version']}",
  monitord_user     => $::fuel_settings['keystone']['monitord_user'],
  monitord_password => $::fuel_settings['keystone']['monitord_password'],
  monitord_tenant   => 'services',
  admin_iface       => $::fuel_settings['ADMIN_NETWORK']['interface'],
}

class { 'openstack::clocksync':
  ntp_servers     => $ntp_servers,
  config_template => 'ntp/ntp.conf.erb',
}

class { 'docker::dockerctl':
  release         => $::fuel_version['VERSION']['release'],
  production      => $production,
  admin_ipaddress => $::fuel_settings['ADMIN_NETWORK']['ipaddress'],
  docker_engine => 'native',
}

class { "docker":
  docker_engine => 'native',
  release => $::fuel_version['VERSION']['release'],
}

class { 'openstack::logrotate':
  role     => 'server',
  rotation => 'weekly',
  keep     => '4',
  minsize  => '10M',
  maxsize  => '100M',
}

class { 'nailgun::client':
  server        => $::fuel_settings['ADMIN_NETWORK']['ipaddress'],
  keystone_user => $::fuel_settings['FUEL_ACCESS']['user'],
  keystone_pass => $::fuel_settings['FUEL_ACCESS']['password'],
}

class { 'nailgun::supervisor':
  nailgun_env => false,
  ostf_env    => false,
  require     => File['/etc/supervisord.d/current', "/etc/supervisord.d/${::fuel_version['VERSION']['release']}"],
  conf_file   => 'nailgun/supervisord.conf.base.erb',
}

class { 'osnailyfacter::ssh':
  password_auth => 'yes',
}

file { '/etc/supervisord.d':
  ensure  => directory,
}

class { 'docker::supervisor':
  release => $::fuel_version['VERSION']['release'],
  require => File["/etc/supervisord.d/${::fuel_version['VERSION']['release']}"],
}

file { "/etc/supervisord.d/${::fuel_version['VERSION']['release']}":
  ensure  => directory,
  require => File['/etc/supervisord.d'],
  owner   => root,
  group   => root,
}

file { '/etc/supervisord.d/current':
  ensure  => link,
  target  => "/etc/supervisord.d/${::fuel_version['VERSION']['release']}",
  require => File["/etc/supervisord.d/${::fuel_version['VERSION']['release']}"],
  replace => true,
}

exec {'sync_deployment_tasks':
  command   => 'fuel rel --sync-deployment-tasks --dir /etc/puppet/',
  path      => '/usr/bin',
  tries     => 12,
  try_sleep => 10,
  require   => Class['nailgun::supervisor']
}
