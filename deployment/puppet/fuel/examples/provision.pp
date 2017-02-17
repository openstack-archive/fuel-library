notice('MODULAR: provision.pp')

Exec {path => '/usr/bin:/bin:/usr/sbin:/sbin'}

$fuel_settings               = parseyaml($astute_settings_yaml)

$mco_user                    = $::fuel_settings['mcollective']['user']
$mco_pass                    = $::fuel_settings['mcollective']['password']
$dns_address                 = $::fuel_settings['ADMIN_NETWORK']['ipaddress']
$domain_name                 = $::fuel_settings['DNS_DOMAIN']
$dns_search                  = $::fuel_settings['DNS_SEARCH']
$forwarders                  = split($::fuel_settings['DNS_UPSTREAM'], ',')
$start_address               = $::fuel_settings['ADMIN_NETWORK']['dhcp_pool_start']
$end_address                 = $::fuel_settings['ADMIN_NETWORK']['dhcp_pool_end']
$network_mask                = $::fuel_settings['ADMIN_NETWORK']['netmask']
$network_address             = ipcalc_network_by_address_netmask($start_address, $network_mask)
$dhcp_gateway                = $::fuel_settings['ADMIN_NETWORK']['dhcp_gateway']
if $dhcp_gateway {
  $router = $dhcp_gateway
}
else {
  $router = $::fuel_settings['ADMIN_NETWORK']['ipaddress']
}

$next_server                 = $::fuel_settings['ADMIN_NETWORK']['ipaddress']

$nailgun_api_url             = "http://${::fuel_settings['ADMIN_NETWORK']['ipaddress']}:8000/api"
$ethdevice_timeout           = hiera('ethdevice_timeout')

$ddns_key = hiera('ddns_key')
$ddns_key_algorithm = hiera('ddns_key_algorithm')
$ddns_key_name = hiera('ddns_key_name')

$bootstrap_menu_label = hiera('bootstrap_menu_label')
$bootstrap_kernel_path = hiera('bootstrap_kernel_path')
$bootstrap_initrd_path = hiera('bootstrap_initrd_path')

$bootstrap_settings = pick($::fuel_settings['BOOTSTRAP'], {})
$bootstrap_path = pick($bootstrap_settings['path'], '/var/www/nailgun/bootstraps/active_bootstrap')
$metadata_yaml = file("${bootstrap_path}/metadata.yaml", '/dev/null')
if empty($metadata_yaml) {
  $bootstrap_meta = {}
} else {
  $bootstrap_meta = parseyaml($metadata_yaml)
}

$bootstrap_kernel_params = extend_kopts($bootstrap_meta['extend_kopts'], "console=ttyS0,9600 console=tty0 panic=60 ethdevice-timeout=${ethdevice_timeout} boot=live toram components fetch=http://${next_server}:8080/bootstraps/active_bootstrap/root.squashfs biosdevname=0 url=${nailgun_api_url} mco_user=${mco_user} mco_pass=${mco_pass} ip=frommedia")

$known_hosts = hiera_array('known_hosts')
$chain32_files = tftp_files("/var/lib/tftpboot/pxelinux.cfg", $known_hosts)

class { "::provision::dhcpd" :
  network_address => ipcalc_network_by_address_netmask($start_address, $network_mask),
  network_mask => $network_mask,
  broadcast_address => $broadcast_address,
  start_address => $start_address,
  end_address => $end_address,
  router => $router,
  next_server => $next_server,
  dns_address => $dns_address,
  domain_name => $domain_name,
  ddns_key => $ddns_key,
  ddns_key_algorithm => $ddns_key_algorithm,
  ddns_key_name => $ddns_key_name,
  known_hosts => $known_hosts,
}

class { "::provision::tftp" :
  bootstrap_menu_label => $bootstrap_menu_label,
  bootstrap_kernel_path => $bootstrap_kernel_path,
  bootstrap_initrd_path => $bootstrap_initrd_path,
  bootstrap_kernel_params => $bootstrap_kernel_params,
  chain32_files => $chain32_files,
} ->

file { "/var/lib/tftpboot${bootstrap_kernel_path}" :
  source => "${bootstrap_path}/vmlinuz",
} ->

file { "/var/lib/tftpboot${bootstrap_initrd_path}" :
  source => "${bootstrap_path}/initrd.img"
}

class { "::provision::named" :
  domain_name => $domain_name,
  dns_address => $dns_address,
  forwarders => $forwarders,
  ddns_key => $ddns_key,
  ddns_key_algorithm => $ddns_key_algorithm,
  ddns_key_name => $ddns_key_name,
} ->

file { '/etc/resolv.conf':
  content => template('fuel/resolv.conf.erb'),
  owner   => 'root',
  group   => 'root',
  mode    => '0644',
}
