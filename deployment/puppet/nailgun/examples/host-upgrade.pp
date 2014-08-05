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
Class['nailgun::host'] ->
Class['docker::dockerctl'] ->
Class['docker'] ->
Class['openstack::logrotate'] ->
Class['nailgun::client']

class { 'nailgun::packages': }

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
  config_template => "ntp/ntp.conf.centosserver.erb",
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

