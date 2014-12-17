import 'common/globals.pp'

if $disable_offload {
  L23network::L3::Ifconfig<||> {
    ethtool => {
      'K' => ['gso off',  'gro off'],
    }
  }
}

class { 'l23network' :
  use_ovs => $use_neutron,
}

class advanced_node_netconfig {
  $sdn = generate_network_config()
  notify {"SDN: ${sdn}": }
}

if $use_neutron {
  class {'advanced_node_netconfig': }
} else {
  class { 'osnailyfacter::network_setup': }
}

class { 'openstack::firewall' :
  nova_vnc_ip_range => $management_network_range,
}

# setting kernel reserved ports
# defaults are 49000,35357,41055,58882
class { 'openstack::reserved_ports': }

# Workaround for fuel bug with firewall
firewall {'003 remote rabbitmq ':
  sport   => [ 4369, 5672, 15672, 41055, 55672, 61613 ],
  source  => $master_ip,
  proto   => 'tcp',
  action  => 'accept',
  require => Class['openstack::firewall'],
}

firewall {'004 remote puppet ':
  sport   => [ 8140 ],
  source  => $master_ip,
  proto   => 'tcp',
  action  => 'accept',
  require => Class['openstack::firewall'],
}

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
