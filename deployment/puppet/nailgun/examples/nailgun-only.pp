$fuel_settings = parseyaml($astute_settings_yaml)
$fuel_version = parseyaml($fuel_version_yaml)

if is_hash($::fuel_version) and $::fuel_version['VERSION'] and $::fuel_version['VERSION']['production'] {
    $production = $::fuel_version['VERSION']['production']
}
else {
    $production = 'dev'
}

if $production != 'dev' {
  $env_path = "/usr"
  $staticdir = "/usr/share/nailgun/static"
} else {
  $env_path = "/opt/nailgun"
  $staticdir = "/opt/nailgun/share/nailgun/static"
}

Class["nailgun::user"] ->
Class["nailgun::packages"] ->
Class["nailgun::venv"] ->
Class["nailgun::supervisor"]

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
$rabbitmq_astute_user = "naily"
$rabbitmq_astute_password = "naily"

$cobbler_host = $::fuel_settings['ADMIN_NETWORK']['ipaddress']
$cobbler_url = "http://${::fuel_settings['ADMIN_NETWORK']['ipaddress']}:80/cobbler_api"
$cobbler_user = "cobbler"
$cobbler_password = "cobbler"

$mco_pskey = "unset"
$mco_vhost = "mcollective"
$mco_host = $::fuel_settings['ADMIN_NETWORK']['ipaddress']
$mco_user = "mcollective"
$mco_password = "marionette"
$mco_connector = "rabbitmq"

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

  database_name => "nailgun",
  database_engine => "postgresql",
  database_host => $::fuel_settings['ADMIN_NETWORK']['ipaddress'],
  database_port => "5432",
  database_user => "nailgun",
  database_passwd => "nailgun",

  staticdir => $staticdir,
  templatedir => $templatedir,
  rabbitmq_host => $rabbitmq_host,
  rabbitmq_astute_user => $rabbitmq_astute_user,
  rabbitmq_astute_password => $rabbitmq_astute_password,

  admin_network         => ipcalc_network_by_address_netmask($::fuel_settings['ADMIN_NETWORK']['ipaddress'], $::fuel_settings['ADMIN_NETWORK']['netmask']),
  admin_network_cidr    => ipcalc_network_cidr_by_netmask($::fuel_settings['ADMIN_NETWORK']['netmask']),
  admin_network_size    => ipcalc_network_count_addresses($::fuel_settings['ADMIN_NETWORK']['ipaddress'], $::fuel_settings['ADMIN_NETWORK']['netmask']),
  admin_network_first   => $::fuel_settings['ADMIN_NETWORK']['static_pool_start'],
  admin_network_last    => $::fuel_settings['ADMIN_NETWORK']['static_pool_end'],
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
}
class { "nailgun::supervisor":
  nailgun_env   => $env_path,
  ostf_env      => $env_path,
  conf_file => "nailgun/supervisord.conf.nailgun.erb",
}

