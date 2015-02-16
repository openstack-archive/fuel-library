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

# Nailgun settings
$staticdir = "/usr/share/nailgun/static"
$templatedir = $staticdir

$rabbitmq_host = $::fuel_settings['ADMIN_NETWORK']['ipaddress']
$rabbitmq_astute_user = $::fuel_settings['astute']['user']
$rabbitmq_astute_password = $::fuel_settings['astute']['password']

$cobbler_host = $::fuel_settings['ADMIN_NETWORK']['ipaddress']
$cobbler_url = "http://${::fuel_settings['ADMIN_NETWORK']['ipaddress']}:80/cobbler_api"
$cobbler_user = $::fuel_settings['cobbler']['user']
$cobbler_password = $::fuel_settings['cobbler']['password']

$mco_pskey = "unset"
$mco_vhost = "mcollective"
$mco_host = $::fuel_settings['ADMIN_NETWORK']['ipaddress']
$mco_user = $::fuel_settings['mcollective']['user']
$mco_password = $::fuel_settings['mcollective']['password']
$mco_connector = "rabbitmq"

$keystone_host = $::fuel_settings['ADMIN_NETWORK']['ipaddress']
$keystone_nailgun_user = $::fuel_settings['keystone']['nailgun_user']
$keystone_nailgun_pass = $::fuel_settings['keystone']['nailgun_password']

#deprecated
$puppet_master_hostname = "${::fuel_settings['HOSTNAME']}.${::fuel_settings['DNS_DOMAIN']}"


Class['nailgun::packages'] ->
Class['nailgun::client'] ->
Class['nailgun::host'] ->
Class['docker::dockerctl'] ->
Class['docker'] ->
Class['openstack::logrotate'] ->
Class['nailgun::supervisor']

class { 'nailgun::packages': }

class { 'osnailyfacter::atop': }

class { 'nailgun::host':
  production    => $production,
  nailgun_group => $nailgun_group,
  nailgun_user  => $nailgun_user,
  dns_domain    => $::fuel_settings['DNS_DOMAIN'],
  dns_search    => $::fuel_settings['DNS_SEARCH'],

  database_name   => $::fuel_settings['postgres']['nailgun_dbname'],
  database_engine => "postgresql",
  database_host   => $::fuel_settings['ADMIN_NETWORK']['ipaddress'],
  database_port   => "5432",
  database_user   => $::fuel_settings['postgres']['nailgun_user'],
  database_passwd => $::fuel_settings['postgres']['nailgun_password'],

  staticdir                => $staticdir,
  templatedir              => $templatedir,
  rabbitmq_host            => $rabbitmq_host,
  rabbitmq_astute_user     => $rabbitmq_astute_user,
  rabbitmq_astute_password => $rabbitmq_astute_password,

  admin_network         => ipcalc_network_by_address_netmask($::fuel_settings['ADMIN_NETWORK']['ipaddress'],$::fuel_settings['ADMIN_NETWORK']['netmask']),
  admin_network_cidr    => ipcalc_network_cidr_by_netmask($::fuel_settings['ADMIN_NETWORK']['netmask']),
  admin_network_size    => ipcalc_network_count_addresses($::fuel_settings['ADMIN_NETWORK']['ipaddress'],
$::fuel_settings['ADMIN_NETWORK']['netmask']),
  admin_network_first   => $::fuel_settings['ADMIN_NETWORK']['dhcp_pool_start'],
  admin_network_last    => $::fuel_settings['ADMIN_NETWORK']['dhcp_pool_end'],
  admin_network_netmask => $::fuel_settings['ADMIN_NETWORK']['netmask'],
  admin_network_mac     => $::fuel_settings['ADMIN_NETWORK']['mac'],
  admin_network_ip      => $::fuel_settings['ADMIN_NETWORK']['ipaddress'],

  cobbler_host     => $cobbler_host,
  cobbler_url      => $cobbler_url,
  cobbler_user     => $cobbler_user,
  cobbler_password => $cobbler_password,

  mco_pskey     => $mco_pskey,
  mco_vhost     => $mco_vhost,
  mco_host      => $mco_host,
  mco_user      => $mco_user,
  mco_password  => $mco_password,
  mco_connector => $mco_connector,

  puppet_master_hostname => $puppet_master_hostname,

  keystone_host         => $keystone_host,
  keystone_nailgun_user => $keystone_nailgun_user,
  keystone_nailgun_pass => $keystone_nailgun_pass,
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
class { "docker": }

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
