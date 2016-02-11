class task::dns::dns-server {

  notice('MODULAR: dns-server.pp')
  
  $dns_servers            = hiera('external_dns')
  $primary_controller     = hiera('primary_controller')
  $master_ip              = hiera('master_ip')
  $management_vrouter_vip = hiera('management_vrouter_vip')
  $network_metadata       = hiera_hash('network_metadata', {})
  $vrouter_name           = hiera('vrouter_name', 'pub')
  
  # If VIP has namespace set to 'false' or 'undef' then we do not configure it
  # under corosync cluster. So we should not configure anything listening it.
  if $network_metadata['vips']["vrouter_${vrouter_name}"]['namespace'] {
    class { 'osnailyfacter::dnsmasq':
      external_dns           => strip(split($dns_servers['dns_list'], ',')),
      master_ip              => $master_ip,
      management_vrouter_vip => $management_vrouter_vip,
    } ->
  
    class { 'cluster::dns_ocf':
      primary_controller => $primary_controller,
    }
  }

}
