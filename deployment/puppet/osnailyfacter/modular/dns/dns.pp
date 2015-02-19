notice('MODULAR: dns.pp')

$role               = hiera('role')
$dns_servers        = hiera('external_dns')
$management_vip     = hiera('management_vip')
$primary_controller = hiera('primary_controller')
$master_ip          = hiera('master_ip')

if $role =~ /controller/ {

  class { 'osnailyfacter::dnsmasq':
    external_dns => strip(split($dns_servers['dns_list'], ',')),
    master_ip    => $master_ip,
  }

  class { 'cluster::dns_ocf':
    primary_controller => $primary_controller,
  }

  #### to be removed when vrouters implemented ####
  Class['cluster::haproxy'] -> Class['cluster::dns_ocf']
}

class { 'osnailyfacter::resolvconf':
  management_vip => $management_vip,
}
