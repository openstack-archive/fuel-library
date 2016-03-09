class osnailyfacter::dns::dns_server {

  notice('MODULAR: dns/dns_server.pp')

  $dns_servers            = hiera('external_dns')
  $primary_controller     = hiera('primary_controller')
  $master_ip              = hiera('master_ip')
  $management_vrouter_vip = hiera('management_vrouter_vip')
  $network_metadata       = hiera_hash('network_metadata', {})
  $vrouter_name           = hiera('vrouter_name', 'pub')

  if is_array($dns_servers['dns_list']) {
    $external_dns = $dns_servers['dns_list']
  } elsif is_ip_address($dns_servers['dns_list']) {
    $external_dns = any2array($dns_servers['dns_list'])
  } else {
    $external_dns = split($dns_servers['dns_list'], ',')
  }

  # If VIP has namespace set to 'false' or 'undef' then we do not configure it
  # under corosync cluster. So we should not configure anything listening it.
  if $network_metadata['vips']["vrouter_${vrouter_name}"]['namespace'] {
    class { '::osnailyfacter::dnsmasq':
      external_dns           => $external_dns,
      master_ip              => $master_ip,
      management_vrouter_vip => $management_vrouter_vip,
    } ->

    class { '::cluster::dns_ocf':
    }
  }

}
