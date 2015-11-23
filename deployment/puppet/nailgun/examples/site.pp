
$fuel_settings = parseyaml($astute_settings_yaml)

$production         = pick($::fuel_settings['PRODUCTION'], 'prod')
$bootstrap_settings = pick($::fuel_settings['BOOTSTRAP'], {})
$bootstrap_flavor   = pick($bootstrap_settings['flavor'], 'centos')

$env_path  = '/usr'
$staticdir = '/usr/share/nailgun/static'

Exec  {path => '/usr/bin:/bin:/usr/sbin:/sbin'}


#############################
#### HOST
#############################

#Purge empty NTP server entries
$ntp_servers = delete(delete_undef_values([$::fuel_settings['NTP1'],
                     $::fuel_settings['NTP2'], $::fuel_settings['NTP3']]), "")

$admin_network = ipcalc_network_wildcard(
  $::fuel_settings['ADMIN_NETWORK']['ipaddress'],
  $::fuel_settings['ADMIN_NETWORK']['netmask'])
$extra_networks = $fuel_settings['EXTRA_ADMIN_NETWORKS']

Class['nailgun::packages'] ->
Class['nailgun::host'] ->
Class['nailgun::client'] ->
Class['docker::dockerctl'] ->
Class['docker'] ->
Class['openstack::logrotate'] ->
Class['nailgun::supervisor'] ->
Class['monit']

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
  require     => File['/etc/supervisord.d/current', "/etc/supervisord.d/${::fuel_release}"],
  conf_file   => 'nailgun/supervisord.conf.base.erb',
}

class { 'osnailyfacter::ssh':
  password_auth => 'yes',
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
  owner   => root,
  group   => root,
}

file { '/etc/supervisord.d/current':
  ensure  => link,
  target  => "/etc/supervisord.d/${::fuel_release}",
  require => File["/etc/supervisord.d/${::fuel_release}"],
  replace => true,
}

exec {'sync_deployment_tasks':
  command   => 'fuel rel --sync-deployment-tasks --dir /etc/puppet/',
  path      => '/usr/bin',
  tries     => 12,
  try_sleep => 10,
  require   => Class['nailgun::supervisor']
}

#############################
#### ASTUTE
#############################


$mco_host      = $::fuel_settings['ADMIN_NETWORK']['ipaddress']
$mco_port      = '61613'
$mco_pskey     = 'unset'
$mco_vhost     = 'mcollective'
$mco_user      = $::fuel_settings['mcollective']['user']
$mco_password  = $::fuel_settings['mcollective']['password']
$mco_connector = 'rabbitmq'

$mco_settings = {
  'ttl' => {
    value => '4294957'
  },
  'direct_addressing' => {
    value => '1'
  },
  'plugin.rabbitmq.vhost' => {
    value => $mco_vhost
  },
  'plugin.rabbitmq.pool.size' => {
    value => '1'
  },
  'plugin.rabbitmq.pool.1.host' => {
    value => $mco_host
  },
  'plugin.rabbitmq.pool.1.port' => {
    value => $mco_port
  },
  'plugin.rabbitmq.pool.1.user' => {
    value => $mco_user
  },
  'plugin.rabbitmq.pool.1.password' => {
    value => $mco_password
  },
  'plugin.rabbitmq.heartbeat_interval' => {
    value => '30'
  }
}

$rabbitmq_astute_user     = $::fuel_settings['astute']['user']
$rabbitmq_astute_password = $::fuel_settings['astute']['password']


if $::osfamily == 'RedHat' {
  case $operatingsystemmajrelease {
    '6': {
      $mco_packages = ['ruby21-rubygem-mcollective-client',
                       'ruby21-nailgun-mcagents']
    }
    '7': {
      $mco_packages = ['mcollective-client', 'nailgun-mcagents']
    }
    default: {
      fail("Unsupported ${::osfamily} release: ${::operatingsystemmajrelease}")
    }
  }
}

ensure_packages($mco_packages)

Class['nailgun::astute'] ->
Class['nailgun::supervisor']

class { 'nailgun::astute':
  production               => $production,
  rabbitmq_host            => $::fuel_settings['ADMIN_NETWORK']['ipaddress'],
  rabbitmq_astute_user     => $rabbitmq_astute_user,
  rabbitmq_astute_password => $rabbitmq_astute_password,
  bootstrap_flavor         => $bootstrap_flavor,
}

package { 'supervisor': } ->
class { 'nailgun::supervisor':
  nailgun_env => $env_path,
  ostf_env    => $env_path,
  conf_file   => 'nailgun/supervisord.conf.astute.erb',
}

class { '::mcollective':
  connector        => 'rabbitmq',
  middleware_hosts => [$mco_hosts],
  psk              => $mco_pskey,
  server           => false,
  client           => true,
  manage_packages  => false,
  require          => Package[$mco_packages],
}

create_resources(mcollective::client::setting, $mco_settings, { 'order' => 90 })

##############################
#### COBBLER
##############################

# this replaces removed postgresql version fact
$postgres_default_version = '9.3'


$centos_repos = [
  {
  "id" => "nailgun",
  "name" => "Nailgun",
  "url"  => "\$tree"
  }
]

$cobbler_url        = "http://${::fuel_settings['ADMIN_NETWORK']['ipaddress']}/cobbler_api"
$cobbler_user       = $::fuel_settings['cobbler']['user']
$cobbler_password   = $::fuel_settings['cobbler']['password']
$bootstrap_settings = pick($::fuel_settings['BOOTSTRAP'], {})
$bootstrap_flavor   = pick($bootstrap_settings['flavor'], 'centos')
$bootstrap_ethdevice_timeout = pick($bootstrap_settings['ethdevice_timeout'], '120')
$nailgun_api_url    = "http://${::fuel_settings['ADMIN_NETWORK']['ipaddress']}:8000/api"

$cobbler_host     = $::fuel_settings['ADMIN_NETWORK']['ipaddress']
$dhcp_interface   = $::fuel_settings['ADMIN_NETWORK']['interface']

$dns_upstream       = $::fuel_settings['DNS_UPSTREAM']
$dns_domain         = $::fuel_settings['DNS_DOMAIN']
$dns_search         = $::fuel_settings['DNS_SEARCH']
$dhcp_start_address = $::fuel_settings['ADMIN_NETWORK']['dhcp_pool_start']
$dhcp_end_address   = $::fuel_settings['ADMIN_NETWORK']['dhcp_pool_end']
$dhcp_netmask       = $::fuel_settings['ADMIN_NETWORK']['netmask']

$dhcp_gw            = $::fuel_settings['ADMIN_NETWORK']['dhcp_gateway']
if $dhcp_gw {
  $dhcp_gateway = $dhcp_gw
} else {
  $dhcp_gateway = $cobbler_host
}

$puppet_master_hostname = "${hostname}.${domain}"

$mco_pskey = "unset"
$mco_vhost = "mcollective"
$mco_user = $::fuel_settings['mcollective']['user']
$mco_password = $::fuel_settings['mcollective']['password']
$mco_connector = "rabbitmq"

$rabbitmq_naily_user = $::fuel_settings['astute']['user']
$rabbitmq_naily_password = $::fuel_settings['astute']['password']

$repo_root = "/var/www/nailgun"
$pip_repo = "/var/www/nailgun/eggs"
$gem_source = "http://${::fuel_settings['ADMIN_NETWORK']['ipaddress']}:8080/gems/"

class { "nailgun::cobbler":
  production   => $production,
  centos_repos => $centos_repos,
  gem_source   => $gem_source,

  cobbler_user       => $cobbler_user,
  cobbler_password   => $cobbler_password,
  bootstrap_flavor   => $bootstrap_flavor,
  server             => $cobbler_host,
  name_server        => $cobbler_host,
  next_server        => $cobbler_host,

  mco_user           => $mco_user,
  mco_pass           => $mco_password,

  dns_upstream       => $dns_upstream,
  dns_domain         => $dns_domain,
  dns_search         => $dns_search,
  dhcp_start_address => $dhcp_start_address,
  dhcp_end_address   => $dhcp_end_address,
  dhcp_netmask       => $dhcp_netmask,
  dhcp_gateway       => $dhcp_gateway,
  dhcp_interface     => $dhcp_interface,
  nailgun_api_url    => $nailgun_api_url,

  bootstrap_ethdevice_timeout => $bootstrap_ethdevice_timeout,
}


###############################
#### KEYSTONE
###############################

package { 'python-psycopg2':
  ensure => installed,
}

$auth_version = "v2.0"

class { 'keystone':
  admin_token      => $::fuel_settings['keystone']['admin_token'],
  catalog_type     => 'sql',
  database_connection   => "postgresql://${::fuel_settings['postgres']['keystone_user']}:${::fuel_settings['postgres']['keystone_password']}@${::fuel_settings['ADMIN_NETWORK']['ipaddress']}/${::fuel_settings['postgres']['keystone_dbname']}",
  token_expiration => 86400,
  token_provider   => 'keystone.token.providers.uuid.Provider',
}

#FIXME(mattymo): We should enable db_sync on every run inside keystone,
#but this is related to a larger scope fix for concurrent deployment of
#secondary controllers.
Exec <| title == 'keystone-manage db_sync' |> {
  refreshonly => false,
}

# Admin user
keystone_tenant { 'admin':
  ensure  => present,
  enabled => 'True',
}

keystone_tenant { 'services':
  ensure      => present,
  enabled     => 'True',
  description => 'fuel services tenant',
}

keystone_role { 'admin':
  ensure => present,
}

keystone_user { 'admin':
  ensure          => present,
  password        => $::fuel_settings['FUEL_ACCESS']['password'],
  enabled         => 'True',
  tenant          => 'admin',
  replace_password => false,
}

keystone_user_role { 'admin@admin':
  ensure => present,
  roles  => ['admin'],
}

# Monitord user
keystone_role { 'monitoring':
  ensure => present,
}

keystone_user { $::fuel_settings['keystone']['monitord_user']:
  ensure   => present,
  password => $::fuel_settings['keystone']['monitord_password'],
  enabled  => 'True',
  email    => 'monitord@localhost',
  tenant   => 'services',
}

keystone_user_role { 'monitord@services':
  ensure => present,
  roles  => ['monitoring'],
}

# Keystone Endpoint
class { 'keystone::endpoint':
  public_url   => "http://${::fuel_settings['ADMIN_NETWORK']['ipaddress']}:5000/${auth_version}",
  admin_url    => "http://${::fuel_settings['ADMIN_NETWORK']['ipaddress']}:35357/${auth_version}",
  internal_url => "http://${::fuel_settings['ADMIN_NETWORK']['ipaddress']}:5000/${auth_version}",
}

# Nailgun
class { 'nailgun::auth':
  auth_name => $::fuel_settings['keystone']['nailgun_user'],
  password  => $::fuel_settings['keystone']['nailgun_password'],
  address   => $::fuel_settings['ADMIN_NETWORK']['ipaddress'],
}

# OSTF
class { 'nailgun::ostf::auth':
  auth_name => $::fuel_settings['keystone']['ostf_user'],
  password  => $::fuel_settings['keystone']['ostf_password'],
  address   => $::fuel_settings['ADMIN_NETWORK']['ipaddress'],
}

package { 'crontabs':
  ensure => latest,
}

service { 'crond':
  ensure => running,
  enable => true,
}

# Flush expired tokens
cron { 'keystone-flush-token':
  ensure      => present,
  command     => 'keystone-manage token_flush',
  environment => 'PATH=/bin:/usr/bin:/usr/sbin',
  user        => 'root',
  hour        => '1',
  require     => Package['crontabs'],
}


##################################
#### MCOLLECTIVE
##################################

if $::osfamily == 'RedHat' {
  case $operatingsystemmajrelease {
    '6': {
      $mco_packages = ['ruby21-mcollective', 'ruby21-nailgun-mcagents']
    }
    '7': {
      $mco_packages = ['mcollective', 'nailgun-mcagents']
    }
    default: {
      fail("Unsupported ${::osfamily} release: ${::operatingsystemmajrelease}")
    }
  }
} else {
  fail("Unsupported operating system: ${::osfamily}")
}

ensure_packages($mco_packages)

class { '::mcollective':
  connector        => 'rabbitmq',
  middleware_hosts => [$mco_hosts],
  server_loglevel  => 'debug',
  psk              => $mco_pskey,
  manage_packages  => false,
  require          => Package[$mco_packages],
}

# class { '::mcollective':
#   connector        => 'rabbitmq',
#   middleware_hosts => [$mco_hosts],
#   psk              => $mco_pskey,
#   server           => false,
#   client           => true,
#   manage_packages  => false,
#   require          => Package[$mco_packages],
# }

create_resources(mcollective::server::setting, $mco_settings, { 'order' => 90 })

class { 'nailgun::mcollective': }

Class['::mcollective'] ->
Class['nailgun::mcollective']


################################
#### NAILGUN
################################

if $::fuel_settings['FEATURE_GROUPS'] {
  $feature_groups = $::fuel_settings['FEATURE_GROUPS']
}
else {
  $feature_groups = []
}

Class["nailgun::user"] ->
Class["nailgun::packages"] ->
Class["nailgun::venv"] ->
Class["nailgun::supervisor"]

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

$ntp_server_list = delete(delete_undef_values([$::fuel_settings['NTP1'],
  $::fuel_settings['NTP2'], $::fuel_settings['NTP3']]), '')
$ntp_servers = join($ntp_server_list, ', ')

$dns_upstream = regsubst($::fuel_settings['DNS_UPSTREAM'], ' ', ', ', 'G')

#deprecated
$puppet_master_hostname = "${::fuel_settings['HOSTNAME']}.${::fuel_settings['DNS_DOMAIN']}"

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
  ntp_upstream => $ntp_servers,
}

class { 'nailgun::uwsgi':
  production => $production,
}

class { "nailgun::client":
  server        => $::fuel_settings['ADMIN_NETWORK']['ipaddress'],
  keystone_user => $::fuel_settings['FUEL_ACCESS']['user'],
  keystone_pass => $::fuel_settings['FUEL_ACCESS']['password'],
}

class { "nailgun::supervisor":
  service_enabled => false,
  nailgun_env     => $env_path,
  ostf_env        => $env_path,
  conf_file       => "nailgun/supervisord.conf.nailgun.erb",
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

##############################
#### NGINX
##############################

if $fuel_settings['SSL'] {
  $force_https = $fuel_settings['SSL']['force_https']
} else {
  $force_https = undef
}

$ostf_host = $::fuel_settings['ADMIN_NETWORK']['ipaddress']
$keystone_host = $::fuel_settings['ADMIN_NETWORK']['ipaddress']
$nailgun_host = $::fuel_settings['ADMIN_NETWORK']['ipaddress']

class { 'nailgun::nginx':
  production      => $production,
  staticdir       => $staticdir,
  templatedir     => $staticdir,
  logdumpdir      => $logdumpdir,
  ostf_host       => $ostf_host,
  keystone_host   => $keystone_host,
  nailgun_host    => $nailgun_host,
  repo_root       => $repo_root,
  service_enabled => false,
  ssl_enabled     => true,
  force_https     => $force_https,
}


################################
#### OSTF
################################

Class['nailgun::packages'] ->
Class['nailgun::ostf'] ->
Class['nailgun::supervisor']

class { "nailgun::packages": }

class { "nailgun::ostf":
  production   => $production,
  pip_opts     => "${pip_index} ${pip_find_links}",
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
class { "nailgun::supervisor":
  nailgun_env   => $env_path,
  ostf_env      => $env_path,
  conf_file => "nailgun/supervisord.conf.base.erb",
}

#################################
#### POSTGRESQL
#################################

# install and configure postgresql server
class { 'postgresql::globals':
  version             => $postgres_default_version,
  bindir              => "/usr/pgsql-${postgres_default_version}/bin",
  server_package_name => "postgresql-server",
  client_package_name => "postgresql",
  encoding            => 'UTF8',
}
class { 'postgresql::server':
  listen_addresses        => '0.0.0.0',
  ip_mask_allow_all_users => '0.0.0.0/0',
}

# nailgun db and grants
$database_name = $::fuel_settings['postgres']['nailgun_dbname']
$database_engine = "postgresql"
$database_port = "5432"
$database_user = $::fuel_settings['postgres']['nailgun_user']
$database_passwd = $::fuel_settings['postgres']['nailgun_password']

class { "nailgun::database":
  user      => $database_user,
  password  => $database_passwd,
  dbname    => $database_name,
}

# keystone db and grants
$keystone_dbname   = $::fuel_settings['postgres']['keystone_dbname']
$keystone_dbuser   = $::fuel_settings['postgres']['keystone_user']
$keystone_dbpass   = $::fuel_settings['postgres']['keystone_password']

postgresql::server::db { $keystone_dbname:
  user     => $keystone_dbuser,
  password => $keystone_dbpass,
  grant    => 'all',
  require => Class['::postgresql::server'],
}

# ostf db and grants
$ostf_dbname   = $::fuel_settings['postgres']['ostf_dbname']
$ostf_dbuser   = $::fuel_settings['postgres']['ostf_user']
$ostf_dbpass   = $::fuel_settings['postgres']['ostf_password']

postgresql::server::db { $ostf_dbname:
  user     => $ostf_dbuser,
  password => $ostf_dbpass,
  grant    => 'all',
  require => Class['::postgresql::server'],
}

Class['postgresql::server'] -> Postgres_config<||>
Postgres_config { ensure => present }
postgres_config {
  log_directory     : value => "'/var/log/'";
  log_filename      : value => "'pgsql'";
  log_rotation_age  : value => "7d";
}

##################################
#### RABBITMQ
##################################

#astute user
$rabbitmq_astute_user = $::fuel_settings['astute']['user']
$rabbitmq_astute_password = $::fuel_settings['astute']['password']

#mcollective user
$mco_user = $::fuel_settings['mcollective']['user']
$mco_password = $::fuel_settings['mcollective']['password']
$mco_vhost = "mcollective"
$stomp = false

$bind_ip = $::fuel_settings['ADMIN_NETWORK']['ipaddress']

$thread_pool_calc = min(100,max(12*$physicalprocessorcount,30))

user { "rabbitmq":
  ensure => present,
  managehome => true,
  uid        => 495,
  shell      => '/bin/bash',
  home       => '/var/lib/rabbitmq',
  comment    => 'RabbitMQ messaging server',
}

file { "/var/log/rabbitmq":
  ensure  => directory,
  owner   => 'rabbitmq',
  group   => 'rabbitmq',
  mode    => 0755,
  require => User['rabbitmq'],
  before  => Service["rabbitmq-server"],
}

class { 'nailgun::rabbitmq':
  production      => $production,
  astute_user     => $rabbitmq_astute_user,
  astute_password => $rabbitmq_astute_password,
  bind_ip         => $bind_ip,
  mco_user        => $mco_user,
  mco_password    => $mco_password,
  mco_vhost       => $mco_vhost,
  stomp           => $stomp,
  env_config      => {
    'RABBITMQ_SERVER_ERL_ARGS' => "+K true +A${thread_pool_calc} +P 1048576",
    'ERL_EPMD_ADDRESS'         => $bind_ip,
    'NODENAME'                 => "rabbit@${::hostname}",
  },
}

#################################
#### PUPPETSYNC
#################################
class { "nailgun::puppetsync": }


#################################
#### RSYSLOG
#################################


Class['rsyslog::server'] ->
Class['openstack::logrotate']

class {"::rsyslog::server":
  enable_tcp                => true,
  enable_udp                => true,
  server_dir                => '/var/log/',
  port                      => 514,
  high_precision_timestamps => true,
}

# Fuel specific config for logging parse formats used for /var/log/remote
$show_timezone = true
$logconf = "${::rsyslog::params::rsyslog_d}30-remote-log.conf"
file { $logconf :
  content => template('openstack/30-server-remote-log.conf.erb'),
  require => Class['::rsyslog::server'],
  owner => root,
  group => $::rsyslog::params::run_group,
  mode => 0640,
  notify  => Class["::rsyslog::service"],
}

class { '::openstack::logrotate':
  role     => 'server',
  rotation => 'weekly',
  keep     => '4',
  minsize  => '10M',
  maxsize  => '20M',
}
