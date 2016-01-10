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
    if $::operatingsystemmajrelease >= '7' {
      $use_systemd = true
    } else {
      $use_systemd = false
    }
  }
  default: { $use_systemd = false }
}

Class['nailgun::packages'] ->
Class['nailgun::host'] ->
Class['nailgun::client'] ->
Class['docker::dockerctl'] ->
Class['docker'] ->
Class['openstack::logrotate'] ->
Class['monit'] ->
Class['nailgun::bootstrap_cli']

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
  use_systemd     => $use_systemd,
  release         => $::fuel_release,
  production      => $production,
  admin_ipaddress => $::fuel_settings['ADMIN_NETWORK']['ipaddress'],
  docker_engine   => 'native',
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

class { 'nailgun::bootstrap_cli':
  settings              => $::fuel_settings['BOOTSTRAP'],
  direct_repo_addresses => [ $::fuel_settings['ADMIN_NETWORK']['ipaddress'] ],
  bootstrap_cli_package => 'fuel-bootstrap-cli',
  config_path           => '/etc/fuel-bootstrap-cli/fuel_bootstrap_cli.yaml',
}

class { 'osnailyfacter::ssh':
  password_auth  => 'yes',
  listen_address => [$::fuel_settings['ADMIN_NETWORK']['ipaddress']],
}

file { '/usr/local/bin/mco':
  source  => 'puppet:///modules/nailgun/mco_host_only',
  mode    => '0755',
  owner   => 'root',
  group   => 'root',
}

if $use_systemd {
  class { 'docker::systemd':
    release => $::fuel_release,
  }
  Class['openstack::logrotate'] ->
  Class['docker::systemd'] ->
  Exec['sync_deployment_tasks']
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
  Class['openstack::logrotate'] ->
  Class['docker::supervisor'] ->
  Exec['sync_deployment_tasks']
}

exec {'sync_deployment_tasks':
  command   => 'fuel rel --sync-deployment-tasks --dir /etc/puppet/',
  path      => '/usr/bin',
  tries     => 12,
  try_sleep => 10,
  require   => Class['nailgun::client'],
}

augeas { 'Remove ssh_config SendEnv defaults':
  lens    => "ssh.lns",
  incl    => "/etc/ssh/ssh_config",
  changes => [
    "rm */SendEnv",
    "rm SendEnv",
  ],
}
