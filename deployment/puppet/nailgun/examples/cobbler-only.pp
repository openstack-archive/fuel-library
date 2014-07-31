$fuel_settings = parseyaml($astute_settings_yaml)
$fuel_version = parseyaml($fuel_version_yaml)

$production = $::fuel_version['VERSION']['production']
if $production {
  $env_path = "/usr"
  $staticdir = "/usr/share/nailgun/static"
} else {
  $env_path = "/opt/nailgun"
  $staticdir = "/opt/nailgun/share/nailgun/static"
}

# this replaces removed postgresql version fact
$postgres_default_version = '8.4'

node default {

  Exec  {path => '/usr/bin:/bin:/usr/sbin:/sbin'}

  $centos_repos =
  [
   {
   "id" => "nailgun",
   "name" => "Nailgun",
   "url"  => "\$tree"
   },
   ]

  $cobbler_url        = "http://${::fuel_settings['ADMIN_NETWORK']['ipaddress']}/cobbler_api"
  $cobbler_user       = $::fuel_settings['cobbler']['user']
  $cobbler_password   = $::fuel_settings['cobbler']['password']
  $nailgun_api_url    = "http://${::fuel_settings['ADMIN_NETWORK']['ipaddress']}:8000/api"
  if $production == "docker-build" {
    $cobbler_host     = $::ipaddress
  } else {
    $cobbler_host     = $::fuel_settings['ADMIN_NETWORK']['ipaddress']
  }
  $dns_upstream       = $::fuel_settings['DNS_UPSTREAM']
  $dns_domain         = $::fuel_settings['DNS_DOMAIN']
  $dns_search         = $::fuel_settings['DNS_SEARCH']
  $dhcp_start_address = $::fuel_settings['ADMIN_NETWORK']['dhcp_pool_start']
  $dhcp_end_address   = $::fuel_settings['ADMIN_NETWORK']['dhcp_pool_end']
  $dhcp_netmask       = $::fuel_settings['ADMIN_NETWORK']['netmask']
  if $production =~ /docker/ {
    $dhcp_interface     = "eth0"
  } else {
    $dhcp_interface     = $::fuel_settigs['ADMIN_NETWORK']['interface']
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
  $gem_source =
"http://${::fuel_settings['ADMIN_NETWORK']['ipaddress']}:8080/gems/"


  class { "nailgun::cobbler":
    production   => $production,
    centos_repos => $centos_repos,
    gem_source   => $gem_source,

    cobbler_user       => $cobbler_user,
    cobbler_password   => $cobbler_password,
    server             => '127.0.0.1',
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
    dhcp_gateway       => $cobbler_host,
    dhcp_interface     => $dhcp_interface,
    nailgun_api_url    => $nailgun_api_url,
  }
}
