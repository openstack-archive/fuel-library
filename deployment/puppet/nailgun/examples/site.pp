Exec  {path => '/usr/bin:/bin:/usr/sbin:/sbin'}

$fuel_settings      = parseyaml($astute_settings_yaml)
$production         = pick($::fuel_settings['PRODUCTION'], 'prod')
$bootstrap_settings = pick($::fuel_settings['BOOTSTRAP'], {})
$bootstrap_flavor   = pick($bootstrap_settings['flavor'], 'centos')
$staticdir          = "/usr/share/nailgun/static"
$repo_root          = "/var/www/nailgun"
$logdumpdir         = "/var/www/nailgun/dump"
$env_path           = "/usr"
$dns_upstream       = regsubst($::fuel_settings['DNS_UPSTREAM'], ' ', ', ', 'G')
$ntp_servers        = delete(delete_undef_values([$::fuel_settings['NTP1'], $::fuel_settings['NTP2'], $::fuel_settings['NTP3']]), "")
$ntp_upstream       = join($ntp_servers, ', ')
$admin_network      = ipcalc_network_wildcard($::fuel_settings['ADMIN_NETWORK']['ipaddress'], $::fuel_settings['ADMIN_NETWORK']['netmask'])

#############################
#### ASTUTE
#############################

class { 'nailgun::astute':
  production               => $::production,
  rabbitmq_host            => $::fuel_settings['ADMIN_NETWORK']['ipaddress'],
  rabbitmq_astute_user     => $::fuel_settings['astute']['user'],
  rabbitmq_astute_password => $::fuel_settings['astute']['password'],
  bootstrap_flavor         => $::bootstrap_flavor,
}

##############################
#### COBBLER
##############################

class { "nailgun::cobbler":
  production                  => $::production,
  gem_source                  => "http://${::fuel_settings['ADMIN_NETWORK']['ipaddress']}:8080/gems/",
  cobbler_user                => $::fuel_settings['cobbler']['user'],
  cobbler_password            => $::fuel_settings['cobbler']['password'],
  bootstrap_flavor            => $::bootstrap_flavor,
  bootstrap_path              => pick($bootstrap_settings['path'], '/var/www/nailgun/bootstraps/active_bootstrap'),
  bootstrap_meta              => pick(loadyaml("${bootstrap_path}/metadata.yaml"), {}),
  server                      => $::fuel_settings['ADMIN_NETWORK']['ipaddress'],
  name_server                 => $::fuel_settings['ADMIN_NETWORK']['ipaddress'],
  next_server                 => $::fuel_settings['ADMIN_NETWORK']['ipaddress'],
  mco_user                    => $::fuel_settings['mcollective']['user'],
  mco_pass                    => $::fuel_settings['mcollective']['password'],
  dns_upstream                => $::fuel_settings['DNS_UPSTREAM'],
  dns_domain                  => $::fuel_settings['DNS_DOMAIN'],
  dns_search                  => $::fuel_settings['DNS_SEARCH'],
  dhcp_start_address          => $::fuel_settings['ADMIN_NETWORK']['dhcp_pool_start'],
  dhcp_end_address            => $::fuel_settings['ADMIN_NETWORK']['dhcp_pool_end'],
  dhcp_netmask                => $::fuel_settings['ADMIN_NETWORK']['netmask'],
  dhcp_gateway                => pick($::fuel_settings['ADMIN_NETWORK']['dhcp_gateway'], $::fuel_settings['ADMIN_NETWORK']['ipaddress']),
  dhcp_interface              => $::fuel_settings['ADMIN_NETWORK']['interface'],
  nailgun_api_url             => "http://${::fuel_settings['ADMIN_NETWORK']['ipaddress']}:8000/api",
  bootstrap_ethdevice_timeout => pick($bootstrap_settings['ethdevice_timeout'], '120'),
}


############################
#### KEYSTONE
############################
class { "nailgun::keystone":
  db_name          => $::fuel_settings['postgres']['keystone_dbname'],
  db_user          => $::fuel_settings['postgres']['keystone_user'],
  db_password      => $::fuel_settings['postgres']['keystone_password'],
  db_address       => $::fuel_settings['ADMIN_NETWORK']['ipaddress'],
  public_baseurl   => "http://${::fuel_settings['ADMIN_NETWORK']['ipaddress']}:5000",
  admin_baseurl    => "http://${::fuel_settings['ADMIN_NETWORK']['ipaddress']}:35357",
  internal_baseurl => "http://${::fuel_settings['ADMIN_NETWORK']['ipaddress']}:5000",
  auth_address     => $::fuel_settings['ADMIN_NETWORK']['ipaddress'],
  admin_token      => $::fuel_settings['keystone']['admin_token'],
  admin_password   => $::fuel_settings['FUEL_ACCESS']['password'],
  monit_user       => $::fuel_settings['keystone']['monitord_user'],
  monit_password   => $::fuel_settings['keystone']['monitord_password'],
  nailgun_user     => $::fuel_settings['keystone']['nailgun_user'],
  nailgun_password => $::fuel_settings['keystone']['nailgun_password'],
  ostf_user        => $::fuel_settings['keystone']['ostf_user'],
  ostf_password    => $::fuel_settings['keystone']['ostf_password'],
}

##################################
#### MCOLLECTIVE
##################################

class {"nailgun::mcollective":
  mco_host     => $::fuel_settings['ADMIN_NETWORK']['ipaddress'],
  mco_user     => $::fuel_settings['mcollective']['user'],
  mco_password => $::fuel_settings['mcollective']['password'],
}

##################################
#### NAILGUN
##################################

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

class {"nailgun::nailgun":
  production               => $production,
  venv                     => $env_path,
  staticdir                => $staticdir,
  feature_groups           => $feature_groups,
  log_level                => $nailgun_log_level,

  db_name                  => $::fuel_settings['postgres']['nailgun_dbname'],
  db_host                  => $::fuel_settings['ADMIN_NETWORK']['ipaddress'],
  db_user                  => $::fuel_settings['postgres']['nailgun_user'],
  db_password              => $::fuel_settings['postgres']['nailgun_password'],

  admin_network            => $admin_network,
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

  pip_repo                 => "http://${::fuel_settings['ADMIN_NETWORK']['ipaddress']}:8080/eggs/",
  gem_source               => "http://${::fuel_settings['ADMIN_NETWORK']['ipaddress']}:8080/gems/",

  rabbitmq_host            => $::fuel_settings['ADMIN_NETWORK']['ipaddress'],
  rabbitmq_astute_user     => $::fuel_settings['astute']['user'],
  rabbitmq_astute_password => $::fuel_settings['astute']['password'],

  puppet_master_hostname   => "${::fuel_settings['HOSTNAME']}.${::fuel_settings['DNS_DOMAIN']}",

  keystone_host            => $::fuel_settings['ADMIN_NETWORK']['ipaddress'],
  keystone_nailgun_user    => $::fuel_settings['keystone']['nailgun_user'],
  keystone_nailgun_pass    => $::fuel_settings['keystone']['nailgun_password'],

  keystone_fuel_user       => $::fuel_settings['FUEL_ACCESS']['user'],
  keystone_fuel_pass       => $::fuel_settings['FUEL_ACCESS']['password'],

  nailgun_host             => $::fuel_settings['ADMIN_NETWORK']['ipaddress'],

  ntp_upstream             => $ntp_upstream,
  dns_upstream             => $dns_upstream,
  dns_domain               => $::fuel_settings['DNS_DOMAIN'],
}


##############################
#### NGINX
##############################

if $fuel_settings['SSL'] {
  $force_https = $fuel_settings['SSL']['force_https']
} else {
  $force_https = undef
}

class { 'nailgun::nginx':
  production      => $production,
  staticdir       => $staticdir,
  templatedir     => $staticdir,
  logdumpdir      => $logdumpdir,
  ostf_host       => $::fuel_settings['ADMIN_NETWORK']['ipaddress'],
  keystone_host   => $::fuel_settings['ADMIN_NETWORK']['ipaddress'],
  nailgun_host    => $::fuel_settings['ADMIN_NETWORK']['ipaddress'],
  repo_root       => $repo_root,
  service_enabled => true,
  ssl_enabled     => true,
  force_https     => $force_https,
}

################################
#### OSTF
################################

$pip_repo = "http://${::fuel_settings['ADMIN_NETWORK']['ipaddress']}:8080/eggs/"
$pip_opts = "--no-index -f ${pip_repo}"

class { "nailgun::ostf":
  production   => $production,
  pip_opts     => $pip_opts,
  dbname       => $::fuel_settings['postgres']['ostf_dbname'],
  dbuser       => $::fuel_settings['postgres']['ostf_user'],
  dbpass       => $::fuel_settings['postgres']['ostf_password'],
  dbhost       => $::fuel_settings['ADMIN_NETWORK']['ipaddress'],
  dbport       => '5432',
  nailgun_host => $::fuel_settings['ADMIN_NETWORK']['ipaddress'],
  nailgun_port => '8000',
  host         => "0.0.0.0",
  auth_enable  => 'True',

  keystone_host      => $::fuel_settings['ADMIN_NETWORK']['ipaddress'],
  keystone_ostf_user => $::fuel_settings['keystone']['ostf_user'],
  keystone_ostf_pass => $::fuel_settings['keystone']['ostf_password'],
}

#################################
#### POSTGRESQL
#################################

class {"nailgun::postgresql":
  nailgun_db_name      => $::fuel_settings['postgres']['nailgun_dbname'],
  nailgun_db_user      => $::fuel_settings['postgres']['nailgun_user'],
  nailgun_db_password  => $::fuel_settings['postgres']['nailgun_password'],

  keystone_db_name     => $::fuel_settings['postgres']['keystone_dbname'],
  keystone_db_user     => $::fuel_settings['postgres']['keystone_user'],
  keystone_db_password => $::fuel_settings['postgres']['keystone_password'],

  ostf_db_name         => $::fuel_settings['postgres']['ostf_dbname'],
  ostf_db_user         => $::fuel_settings['postgres']['ostf_user'],
  ostf_db_password     => $::fuel_settings['postgres']['ostf_password'],
}

##################################
#### RABBITMQ
##################################

$bind_ip = $::fuel_settings['ADMIN_NETWORK']['ipaddress']

$thread_pool_calc = min(100,max(12*$physicalprocessorcount,30))

class { 'nailgun::rabbitmq':
  production      => $production,
  astute_user     => $::fuel_settings['astute']['user'],
  astute_password => $::fuel_settings['astute']['password'],
  bind_ip         => $bind_ip,
  mco_user        => $::fuel_settings['mcollective']['user'],
  mco_password    => $::fuel_settings['mcollective']['password'],
  stomp           => false,
  env_config      => {
    'RABBITMQ_SERVER_ERL_ARGS' => "+K true +A${thread_pool_calc} +P 1048576",
    'ERL_EPMD_ADDRESS'         => $bind_ip,
    'NODENAME'                 => "rabbit@${::hostname}",
  },
}

#############################
#### SUPERVISOR
#############################

class { 'nailgun::supervisor':
  nailgun_env => $env_path,
  ostf_env    => $env_path,
}

exec {'sync_deployment_tasks':
  command   => 'fuel rel --sync-deployment-tasks --dir /etc/puppet/',
  path      => '/usr/bin',
  tries     => 12,
  try_sleep => 10,
  require   => Class['nailgun::supervisor']
}

#############################
#### HOST
#############################

class { 'openstack::clocksync':
  ntp_servers     => $ntp_servers,
  config_template => 'ntp/ntp.conf.erb',
}

class { "nailgun::puppetsync": }
class { 'nailgun::rsyslog': }
class { 'osnailyfacter::atop': }
class { 'osnailyfacter::ssh':
  password_auth => 'yes',
}

class { 'nailgun::packages': }

class { 'nailgun::host':
  production        => $production,
  fuel_version      => $::fuel_release,
  cobbler_host      => $::fuel_settings['ADMIN_NETWORK']['ipaddress'],
  dns_domain        => $::fuel_settings['DNS_DOMAIN'],
  dns_search        => $::fuel_settings['DNS_SEARCH'],
  dns_upstream      => split($::fuel_settings['DNS_UPSTREAM'], ','),
  admin_network     => $admin_network,
  extra_networks    => $::fuel_settings['EXTRA_ADMIN_NETWORKS'],
  repo_root         => "/var/www/nailgun/${::fuel_openstack_version}",
  monitord_user     => $::fuel_settings['keystone']['monitord_user'],
  monitord_password => $::fuel_settings['keystone']['monitord_password'],
  monitord_tenant   => 'services',
  admin_iface       => $::fuel_settings['ADMIN_NETWORK']['interface'],
}

Class['nailgun::packages'] ->
Class['nailgun::rsyslog'] ->
Class['nailgun::host'] ->
Class['nailgun::nginx'] ->
Class['openstack::clocksync'] ->
Class['openstack::logrotate'] ->
Class['nailgun::rabbitmq'] ->
Class['nailgun::mcollective'] ->
Class['nailgun::postgresql'] ->
Class['nailgun::keystone'] ->
Class['nailgun::astute'] ->
Class['nailgun::nailgun'] ->
Class['nailgun::ostf'] ->
Class['nailgun::cobbler'] ->
Class['nailgun::supervisor']
