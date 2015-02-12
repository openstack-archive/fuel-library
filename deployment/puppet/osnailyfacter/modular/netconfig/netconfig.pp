notice('MODULAR: netconfig.pp')

$network_scheme = hiera('network_scheme')

#todo(sv): temporary commented. Will be enabled later as part of
#          'disable-offloading' re-implementation
#if  hiera('disable_offload') {
#  L23network::L3::Ifconfig<||> {
#    ethtool => {
#      'K' => ['gso off',  'gro off'],
#    }
#  }
#}

if $network_scheme['provider'] == 'lnx' {
  class { 'l23network' :
    #    use_ovs => false,
    use_lnx => true,
  }
} else {
  class { 'l23network' :
    use_ovs => true,
    use_lnx => false,
  }
}

class advanced_node_netconfig {
  $sdn = generate_network_config()
  notify {"SDN: ${sdn}": }
}

prepare_network_config(hiera('network_scheme'))
class {'advanced_node_netconfig': }

# setting kernel reserved ports
# defaults are 49000,35357,41055,58882
class { 'openstack::reserved_ports': }

### TCP connections keepalives and failover related parameters ###
# configure TCP keepalive for host OS.
# Send 3 probes each 8 seconds, if the connection was idle
# for a 30 seconds. Consider it dead, if there was no responces
# during the check time frame, i.e. 30+3*8=54 seconds overall.
# (note: overall check time frame should be lower then
# nova_report_interval).
class { 'openstack::keepalive' :
  tcpka_time      => '30',
  tcpka_probes    => '8',
  tcpka_intvl     => '3',
  tcp_retries2    => '5',
}
