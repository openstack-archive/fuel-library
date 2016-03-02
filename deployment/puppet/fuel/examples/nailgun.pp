notice('MODULAR: nailgun.pp')

$fuel_settings = parseyaml($astute_settings_yaml)

if $::fuel_settings['FEATURE_GROUPS'] {
  $feature_groups = $::fuel_settings['FEATURE_GROUPS']
}
else {
  $feature_groups = []
}

$debug = pick($::fuel_settings['DEBUG'],false)
if $debug {
    $nailgun_log_level = "DEBUG"
} else {
    $nailgun_log_level = "INFO"
}

if empty($::fuel_settings['NTP1']) and
   empty($::fuel_settings['NTP2']) and
   empty($::fuel_settings['NTP3']) {
  $ntp_servers = [$::fuel_settings['ADMIN_NETWORK']['ipaddress']]
} else {
  $ntp_servers = delete(delete_undef_values([$::fuel_settings['NTP1'],
    $::fuel_settings['NTP2'], $::fuel_settings['NTP3']]), '')
}

$dns_servers = strip(split($::fuel_settings['DNS_UPSTREAM'], ','))

Exec  {path => '/usr/bin:/bin:/usr/sbin:/sbin'}

class { "fuel::nailgun::server":
  keystone_host            => $::fuel_settings['ADMIN_NETWORK']['ipaddress'],
  keystone_user            => $::fuel_settings['keystone']['nailgun_user'],
  keystone_password        => $::fuel_settings['keystone']['nailgun_password'],

  feature_groups           => $feature_groups,
  nailgun_log_level        => $nailgun_log_level,

  db_name                  => $::fuel_settings['postgres']['nailgun_dbname'],
  db_host                  => $::fuel_settings['ADMIN_NETWORK']['ipaddress'],
  db_user                  => $::fuel_settings['postgres']['nailgun_user'],
  db_password              => $::fuel_settings['postgres']['nailgun_password'],

  rabbitmq_host            => $::fuel_settings['ADMIN_NETWORK']['ipaddress'],
  rabbitmq_astute_user     => $::fuel_settings['astute']['user'],
  rabbitmq_astute_password => $::fuel_settings['astute']['password'],

  admin_network            => ipcalc_network_by_address_netmask($::fuel_settings['ADMIN_NETWORK']['ipaddress'], $::fuel_settings['ADMIN_NETWORK']['netmask']),
  admin_network_cidr       => ipcalc_network_cidr_by_netmask($::fuel_settings['ADMIN_NETWORK']['netmask']),
  admin_network_size       => ipcalc_network_count_addresses($::fuel_settings['ADMIN_NETWORK']['ipaddress'], $::fuel_settings['ADMIN_NETWORK']['netmask']),
  admin_network_first      => $::fuel_settings['ADMIN_NETWORK']['dhcp_pool_start'],
  admin_network_last       => $::fuel_settings['ADMIN_NETWORK']['dhcp_pool_end'],
  admin_network_netmask    => $::fuel_settings['ADMIN_NETWORK']['netmask'],
  admin_network_mac        => $::fuel_settings['ADMIN_NETWORK']['mac'],
  admin_network_ip         => $::fuel_settings['ADMIN_NETWORK']['ipaddress'],
  admin_network_gateway    => $::fuel_settings['ADMIN_NETWORK']['dhcp_gateway'],

  cobbler_host             => $::fuel_settings['ADMIN_NETWORK']['ipaddress'],
  cobbler_url              => "http://${::fuel_settings['ADMIN_NETWORK']['ipaddress']}:80/cobbler_api",
  cobbler_user             => $::fuel_settings['cobbler']['user'],
  cobbler_password         => $::fuel_settings['cobbler']['password'],

  mco_host                 => $::fuel_settings['ADMIN_NETWORK']['ipaddress'],
  mco_user                 => $::fuel_settings['mcollective']['user'],
  mco_password             => $::fuel_settings['mcollective']['password'],

  ntp_upstream             => $ntp_servers,
  dns_upstream             => $dns_servers,
  dns_domain               => $::fuel_settings['DNS_DOMAIN'],
}
