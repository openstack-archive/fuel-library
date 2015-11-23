# Configuration of Fuel Master node only

$fuel_settings = parseyaml($astute_settings_yaml)

if $::fuel_settings['PRODUCTION'] {
    $production = $::fuel_settings['PRODUCTION']
}
else {
    $production = 'docker'
}

#Purge empty NTP server entries
$ntp_servers = delete(delete_undef_values([$::fuel_settings['NTP1'],
                     $::fuel_settings['NTP2'], $::fuel_settings['NTP3']]), "")

$admin_network = ipcalc_network_wildcard(
  $::fuel_settings['ADMIN_NETWORK']['ipaddress'],
  $::fuel_settings['ADMIN_NETWORK']['netmask'])
$extra_networks = $fuel_settings['EXTRA_ADMIN_NETWORKS']

case $::osfamily {
  'RedHat': {
    if $::operatingsystemrelease =~ /^7.*/ {
      $systemd = true
    } else {
      $systemd = false
    }
  }
  default: { $systemd = false }
}

if $systemd {
  Class['nailgun::packages'] ->
  Class['nailgun::host'] ->
  Class['nailgun::client'] ->
  Class['docker::dockerctl'] ->
  Class['docker'] ->
  Class['openstack::logrotate'] ->
  Class['docker::systemd'] ->
  Class['monit']
} else {
  Class['nailgun::packages'] ->
  Class['nailgun::host'] ->
  Class['nailgun::client'] ->
  Class['docker::dockerctl'] ->
  Class['docker'] ->
  Class['openstack::logrotate'] ->
  Class['docker::supervisor'] ->
  Class['monit']
}

class { 'nailgun::packages': }

class { 'osnailyfacter::atop': }

class { 'nailgun::host':
  production        => $production,
  fuel_version      => $::fuel_release,
  cobbler_host      => $::fuel_settings['ADMIN_NETWORK']['ipaddress'],
  nailgun_group     => $nailgun_group,
  nailgun_user      => $nailgun_user,
  dns_domain        => $::fuel_settings['DNS_DOMAIN'],
  dns_search        => $::fuel_settings['DNS_SEARCH'],
  dns_upstream      => split($::fuel_settings['DNS_UPSTREAM'], ','),
  admin_network     => $admin_network,
  extra_networks    => $extra_networks,
  repo_root         => "/var/www/nailgun/${::fuel_openstack_version}",
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
  $systemd        => $systemd,
  release         => $::fuel_release,
  production      => $production,
  admin_ipaddress => $::fuel_settings['ADMIN_NETWORK']['ipaddress'],
  docker_engine => 'native',
}

class { "docker":
  docker_engine => 'native',
  release => $::fuel_release,
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

class { 'osnailyfacter::ssh':
  password_auth => 'yes',
}

if $systemd {
  class { 'docker::systemd':
    release => $::fuel_release,
  }
} else {
  class { 'nailgun::supervisor':
    nailgun_env => false,
    ostf_env    => false,
    require     => File['/etc/supervisord.d/current', "/etc/supervisord.d/${::fuel_release}"],
    conf_file   => 'nailgun/supervisord.conf.base.erb',
  }
  file { '/etc/supervisord.d':
    ensure  => directory,
  }
  class { 'docker::supervisor':
    release => $::fuel_release,
    require => File["/etc/supervisord.d/${::fuel_release}"],
  }
  file { "/etc/supervisord.d/${::fuel_release}":
    ensure  => directory,
    require => File['/etc/supervisord.d'],
    owner   => 'root',
    group   => 'root',
  }
  file { '/etc/supervisord.d/current':
    ensure  => link,
    target  => "/etc/supervisord.d/${::fuel_release}",
    require => File["/etc/supervisord.d/${::fuel_release}"],
    replace => true,
  }
}

if $systemd {
exec {'sync_deployment_tasks':
  command   => 'fuel rel --sync-deployment-tasks --dir /etc/puppet/',
  path      => '/usr/bin',
  tries     => 12,
  try_sleep => 10,
  require   => Class['docker::systemd']
  }
} else {
exec {'sync_deployment_tasks':
  command   => 'fuel rel --sync-deployment-tasks --dir /etc/puppet/',
  path      => '/usr/bin',
  tries     => 12,
  try_sleep => 10,
  require   => Class['nailgun::supervisor']
  }
}
