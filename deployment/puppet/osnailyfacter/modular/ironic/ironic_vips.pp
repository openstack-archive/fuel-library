notice('MODULAR: ironic_vips.pp')

$network_scheme              = hiera('network_scheme', {})
prepare_network_config($network_scheme)
$ironic_hash                 = hiera_hash('ironic', {})

if $ironic_hash['enabled'] {
  if ( hiera('vip_baremetal_cidr_netmask', false )){
    $vip_baremetal_cidr_netmask = hiera('vip_baremetal_cidr_netmask')
  } else {
    $vip_baremetal_cidr_netmask = netmask_to_cidr(get_network_role_property('ironic/baremetal', 'netmask'))
  }
  $baremetal_int = get_network_role_property('ironic/baremetal', 'interface')

  $baremetal_vip_data = {
    namespace      => 'haproxy',
    nic            => $baremetal_int,
    base_veth      => 'br-bare-hapr',
    ns_veth        => 'hapr-b',
    ip             => hiera('baremetal_vip'),
    cidr_netmask   => $vip_baremetal_cidr_netmask,
    gateway        => 'none',
    gateway_metric => '0',
    bridge         => $baremetal_int,
    other_networks => $vip_baremetal_other_nets,
    with_ping      => false,
    ping_host_list => '',
  }

  cluster::virtual_ip { 'baremetal' :
    vip => $baremetal_vip_data,
  }
}
