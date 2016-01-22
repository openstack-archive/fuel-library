$fuel_settings = parseyaml($astute_settings_yaml)

if $::fuel_settings['PRODUCTION'] {
    $production = $::fuel_settings['PRODUCTION']
}
else {
    $production = 'docker'
}

if $production {
  $env_path = "/usr"
  $staticdir = "/usr/share/nailgun/static"
} else {
  $env_path = "/opt/nailgun"
  $staticdir = "/opt/nailgun/share/nailgun/static"
}

# this replaces removed postgresql version fact
$postgres_default_version = '9.3'

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

  $bootstrap_settings          = pick($::fuel_settings['BOOTSTRAP'], {})
  $bootstrap_flavor            = pick($bootstrap_settings['flavor'], 'ubuntu')
  $bootstrap_path              = pick($bootstrap_settings['path'], '/var/www/nailgun/bootstraps/active_bootstrap')
  $bootstrap_meta              = pick(loadyaml("${bootstrap_path}/metadata.yaml"), {})
  $bootstrap_ethdevice_timeout = pick($bootstrap_settings['ethdevice_timeout'], '120')

  if $production == "docker-build" {
    $cobbler_host     = $::ipaddress
    $dhcp_interface     = "eth0"
  } else {
    $cobbler_host     = $::fuel_settings['ADMIN_NETWORK']['ipaddress']
    $dhcp_interface   = $::fuel_settings['ADMIN_NETWORK']['interface']
  }
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
  $gem_source =
"http://${::fuel_settings['ADMIN_NETWORK']['ipaddress']}:8080/gems/"

  class { 'docker::container': }

  class { "nailgun::cobbler":
    production   => $production,
    centos_repos => $centos_repos,
    gem_source   => $gem_source,

    cobbler_user       => $cobbler_user,
    cobbler_password   => $cobbler_password,
    bootstrap_flavor   => $bootstrap_flavor,
    bootstrap_path     => $bootstrap_path,
    bootstrap_meta     => $bootstrap_meta,
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
}
