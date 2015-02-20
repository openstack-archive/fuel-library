notice('MODULAR: netconfig.pp')

$network_scheme = hiera('network_scheme')

$l23network_use_lnx = undef  #todo(sv): pass option from astute.yaml
$l23network_use_ovs = hiera('use_neutron', undef)  # not false, for using defaults
class { 'l23network' :
  use_ovs => $l23network_use_ovs,
  use_lnx => $l23network_use_lnx,
}
prepare_network_config($network_scheme)
$sdn = generate_network_config()
notify {"SDN: ${sdn}": }

#todo(sv): temporary commented. Will be enabled later as part of
#          'disable-offloading' re-implementation
#if  hiera('disable_offload') {
#  L23network::L3::Ifconfig<||> {
#    ethtool => {
#      'K' => ['gso off',  'gro off'],
#    }
#  }
#}


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
