notice('MODULAR: ironic_vips.pp')

$network_scheme = hiera('network_scheme', {})
prepare_network_config($network_scheme)
$ironic_hash    = hiera_hash('ironic', {})

if $ironic_hash['enabled'] {

  $baremetal_int     = get_network_role_property('baremetal', 'interface')
  $baremetal_netmask = get_network_role_property('baremetal', 'netmask')

  $baremetal_vip_data = {
    namespace      => 'haproxy',
    nic            => $baremetal_int,
    base_veth      => 'br-bare-hapr',
    ns_veth        => 'hapr-b',
    ip             => $baremetal_vip,
    cidr_netmask   => $baremetal_netmask,
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
