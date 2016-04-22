class osnailyfacter::virtual_ips::conntrackd {

  notice('MODULAR: virtual_ips/conntrackd.pp')

  $network_metadata = hiera_hash('network_metadata', {})
  prepare_network_config(hiera_hash('network_scheme', {}))
  $vrouter_name = hiera('vrouter_name', 'pub')
  $bind_address = get_network_role_property('mgmt/vip', 'ipaddr')
  $mgmt_bridge = get_network_role_property('mgmt/vip', 'interface')

  # If VIP has namespace set to 'false' or 'undef' then we do not configure
  # it under corosync cluster. So we should not configure colocation with it.
  if $network_metadata['vips']["vrouter_${vrouter_name}"]['namespace'] {
    # CONNTRACKD for CentOS 6 doesn't work under namespaces
    if $::operatingsystem == 'Ubuntu' {
      class { '::cluster::conntrackd_ocf' :
        vrouter_name => $vrouter_name,
        bind_address => $bind_address,
        mgmt_bridge  => $mgmt_bridge,
      }
    }
  }
}
