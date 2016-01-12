$fuel_settings = parseyaml($astute_settings_yaml)

if $::fuel_settings['PRODUCTION'] {
    $production = $::fuel_settings['PRODUCTION']
}
else {
    $production = 'docker'
}

if $::fuel_settings['FEATURE_GROUPS'] {
  $feature_groups = $::fuel_settings['FEATURE_GROUPS']
}
else {
  $feature_groups = []
}

$env_path = "/usr"
$staticdir = "/usr/share/nailgun/static"

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

Class["docker::container"] ->
Class["nailgun::user"] ->
Class["nailgun::packages"] ->
Class["nailgun::venv"]

Exec  {path => '/usr/bin:/bin:/usr/sbin:/sbin'}

$centos_repos =
[
 {
 "id" => "nailgun",
 "name" => "Nailgun",
 "url"  => "\$tree"
 },
]

$repo_root = "/var/www/nailgun"
#$pip_repo = "/var/www/nailgun/eggs"
$pip_repo = "http://${::fuel_settings['ADMIN_NETWORK']['ipaddress']}:8080/eggs/"
$gem_source = "http://${::fuel_settings['ADMIN_NETWORK']['ipaddress']}:8080/gems/"

$package = "Nailgun"
$version = "0.1.0"
$astute_version = "0.0.2"
$nailgun_group = "nailgun"
$nailgun_user = "nailgun"
$venv = $env_path

$pip_index = "--no-index"
$pip_find_links = "-f ${pip_repo}"

$templatedir = $staticdir

$rabbitmq_host = $::fuel_settings['ADMIN_NETWORK']['ipaddress']
$rabbitmq_astute_user = $::fuel_settings['astute']['user']
$rabbitmq_astute_password = $::fuel_settings['astute']['password']

$debug = pick($::fuel_settings['DEBUG'],false)
if $debug {
    $nailgun_log_level = "DEBUG"
} else {
    $nailgun_log_level = "INFO"
}

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

$ntp_server_list = delete(delete_undef_values([$::fuel_settings['NTP1'],
  $::fuel_settings['NTP2'], $::fuel_settings['NTP3']]), '')
$ntp_servers = join($ntp_server_list, ', ')
if empty($ntp_servers) {
  $ntp_servers_real = $::fuel_settings['ADMIN_NETWORK']['ipaddress']
} else {
  $ntp_servers_real = $ntp_servers
}

$dns_upstream = regsubst($::fuel_settings['DNS_UPSTREAM'], ' ', ', ', 'G')

#deprecated
$puppet_master_hostname = "${::fuel_settings['HOSTNAME']}.${::fuel_settings['DNS_DOMAIN']}"

class {'docker::container': }

class { "nailgun::user":
  nailgun_group => $nailgun_group,
  nailgun_user => $nailgun_user,
}
class { "nailgun::packages": }
class { "nailgun::venv":
  venv => $venv,
  venv_opts => "--system-site-packages",
  package => $package,
  version => $version,
  pip_opts => "${pip_index} ${pip_find_links}",
  production => $production,
  nailgun_user => $nailgun_user,
  nailgun_group => $nailgun_group,
  feature_groups => $feature_groups,

  database_name => $::fuel_settings['postgres']['nailgun_dbname'],
  database_engine => "postgresql",
  database_host => $::fuel_settings['ADMIN_NETWORK']['ipaddress'],
  database_port => "5432",
  database_user => $::fuel_settings['postgres']['nailgun_user'],
  database_passwd => $::fuel_settings['postgres']['nailgun_password'],

  staticdir => $staticdir,
  templatedir => $templatedir,
  rabbitmq_host => $rabbitmq_host,
  rabbitmq_astute_user => $rabbitmq_astute_user,
  rabbitmq_astute_password => $rabbitmq_astute_password,

  nailgun_log_level => $nailgun_log_level,

  admin_network         => ipcalc_network_by_address_netmask($::fuel_settings['ADMIN_NETWORK']['ipaddress'], $::fuel_settings['ADMIN_NETWORK']['netmask']),
  admin_network_cidr    => ipcalc_network_cidr_by_netmask($::fuel_settings['ADMIN_NETWORK']['netmask']),
  admin_network_size    => ipcalc_network_count_addresses($::fuel_settings['ADMIN_NETWORK']['ipaddress'], $::fuel_settings['ADMIN_NETWORK']['netmask']),
  admin_network_first   => $::fuel_settings['ADMIN_NETWORK']['dhcp_pool_start'],
  admin_network_last    => $::fuel_settings['ADMIN_NETWORK']['dhcp_pool_end'],
  admin_network_netmask => $::fuel_settings['ADMIN_NETWORK']['netmask'],
  admin_network_mac     => $::fuel_settings['ADMIN_NETWORK']['mac'],
  admin_network_ip      => $::fuel_settings['ADMIN_NETWORK']['ipaddress'],
  admin_network_gateway => $::fuel_settings['ADMIN_NETWORK']['dhcp_gateway'],

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

  keystone_host         => $::fuel_settings['ADMIN_NETWORK']['ipaddress'],
  keystone_nailgun_user => $::fuel_settings['keystone']['nailgun_user'],
  keystone_nailgun_pass => $::fuel_settings['keystone']['nailgun_password'],

  dns_domain   => $::fuel_settings['DNS_DOMAIN'],
  dns_upstream => $dns_upstream,
  ntp_upstream => $ntp_servers_real,
}
class { 'nailgun::uwsgi':
  production => $production,
}
class { "nailgun::client":
  server        => $::fuel_settings['ADMIN_NETWORK']['ipaddress'],
  keystone_user => $::fuel_settings['FUEL_ACCESS']['user'],
  keystone_pass => $::fuel_settings['FUEL_ACCESS']['password'],
}

if $use_systemd {
  $services = [ 'assassind',
                'nailgun',
                'oswl_flavor_collectord',
                'oswl_image_collectord',
                'oswl_keystone_user_collectord',
                'oswl_tenant_collectord',
                'oswl_vm_collectord',
                'oswl_volume_collectord',
                'receiverd',
                'statsenderd' ]
  class { 'nailgun::systemd':
    production => $production,
    services   => $services,
    require    => Class['nailgun::venv']
  }
  if ($production == 'prod') or ($production == 'docker') {
    File['/etc/nailgun/settings.yaml'] ~> Service[$services]
  }

} else {
  class { 'nailgun::supervisor':
    service_enabled => false,
    nailgun_env     => $env_path,
    ostf_env        => $env_path,
    conf_file       => 'nailgun/supervisord.conf.nailgun.erb',
    require         => Class['nailgun::venv']
  }
}

package { 'crontabs':
  ensure => latest,
}

service { 'crond':
  ensure => running,
  enable => true,
}

cron { 'oswl_cleaner':
  ensure      => present,
  command     => 'oswl_cleaner',
  environment => 'PATH=/bin:/usr/bin:/usr/sbin',
  user        => $nailgun_user,
  hour        => '1',
  require     => Package['crontabs'],
}
