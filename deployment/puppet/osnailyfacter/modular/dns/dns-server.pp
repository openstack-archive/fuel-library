notice('MODULAR: dns-server.pp')

$dns_servers            = hiera('external_dns')
$primary_controller     = hiera('primary_controller')
$master_ip              = hiera('master_ip')
$management_vrouter_vip = hiera('management_vrouter_vip')

class { 'osnailyfacter::dnsmasq':
  external_dns           => strip(split($dns_servers['dns_list'], ',')),
  master_ip              => $master_ip,
  management_vrouter_vip => $management_vrouter_vip,
} ->

class { 'cluster::dns_ocf':
  primary_controller => $primary_controller,
}
