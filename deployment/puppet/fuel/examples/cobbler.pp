notice('MODULAR: cobbler.pp')

Exec {path => '/usr/bin:/bin:/usr/sbin:/sbin'}

$fuel_settings               = parseyaml($astute_settings_yaml)
$admin_network               = $::fuel_settings['ADMIN_NETWORK']
$nailgun_api_url             = "http://${::fuel_settings['ADMIN_NETWORK']['ipaddress']}:8000/api"
$bootstrap_settings          = pick($::fuel_settings['BOOTSTRAP'], {})
$bootstrap_path              = pick($bootstrap_settings['path'], '/var/www/nailgun/bootstraps/active_bootstrap')
$bootstrap_ethdevice_timeout = pick($bootstrap_settings['ethdevice_timeout'], '120')
$dhcp_gw                     = $::fuel_settings['ADMIN_NETWORK']['dhcp_gateway']
$dns_domain                  = $::fuel_settings['DNS_DOMAIN']
$dns_search                  = $::fuel_settings['DNS_SEARCH']
$dns_upstream                = split($::fuel_settings['DNS_UPSTREAM'], ',')
$cobbler_host                = $::fuel_settings['ADMIN_NETWORK']['ipaddress']

# TODO(mmalchuk): the right way with updated loadyaml function
# $bootstrap_meta = loadyaml("${bootstrap_path}/metadata.yaml", {})
# and remove if else block
$metadata_yaml = file("${bootstrap_path}/metadata.yaml", '/dev/null')
if empty($metadata_yaml) {
  $bootstrap_meta = {}
} else {
  $bootstrap_meta = parseyaml($metadata_yaml)
}

if $dhcp_gw {
  $dhcp_gateway = $dhcp_gw
}
else {
  $dhcp_gateway = $cobbler_host
}

class { '::fuel::cobbler':
  cobbler_user                => $::fuel_settings['cobbler']['user'],
  cobbler_password            => $::fuel_settings['cobbler']['password'],
  bootstrap_path              => $bootstrap_path,
  bootstrap_meta              => $bootstrap_meta,
  server                      => $::fuel_settings['ADMIN_NETWORK']['ipaddress'],
  name_server                 => $::fuel_settings['ADMIN_NETWORK']['ipaddress'],
  next_server                 => $::fuel_settings['ADMIN_NETWORK']['ipaddress'],
  mco_user                    => $::fuel_settings['mcollective']['user'],
  mco_pass                    => $::fuel_settings['mcollective']['password'],
  dns_upstream                => $dns_upstream,
  dns_domain                  => $dns_domain,
  dns_search                  => $dns_search,
  dhcp_ipaddress              => $::fuel_settings['ADMIN_NETWORK']['ipaddress'],
  nailgun_api_url             => $nailgun_api_url,
  bootstrap_ethdevice_timeout => $bootstrap_ethdevice_timeout,
} ->

file { '/etc/resolv.conf':
  content => template('fuel/resolv.conf.erb'),
  owner   => 'root',
  group   => 'root',
  mode    => '0644',
}

Fuel::Systemd {
  start          => true,
  template_path  => 'fuel/systemd/restart_template.erb',
  config_name    => 'restart.conf',
  service_manage => false,
}

fuel::systemd { ['httpd', 'cobblerd', 'xinetd'] :}

fuel::systemd { 'dnsmasq': template_path => 'fuel/systemd/dnsmasq_template.erb' }

fuel::dnsmasq::dhcp_range {'default':
  dhcp_start_address => $admin_network['dhcp_pool_start'],
  dhcp_end_address   => $admin_network['dhcp_pool_end'],
  dhcp_netmask       => $admin_network['netmask'],
  dhcp_gateway       => $admin_network['dhcp_gateway'],
  next_server        => $admin_network['ipaddress'],
  listen_address     => $admin_network['ipaddress'],
  notify             => Service['dnsmasq'],
}
