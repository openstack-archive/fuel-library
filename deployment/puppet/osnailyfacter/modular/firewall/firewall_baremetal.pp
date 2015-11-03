notice('MODULAR: firewall.pp')

$network_scheme = hiera_hash('network_scheme')
prepare_network_config(hiera_hash('network_scheme'))
$nodes_hash        = hiera('nodes', {})
$roles             = node_roles($nodes_hash, hiera('uid'))
$network_metadata  = hiera_hash('network_metadata', {})
$baremetal_int     = get_network_role_property('ironic/baremetal', 'interface')
$baremetal_vip     = $network_metadata['vips']['baremetal']['ipaddr']
$baremetal_ipaddr  = get_network_role_property('ironic/baremetal', 'ipaddr')
$baremetal_network = get_network_role_property('ironic/baremetal', 'network')

firewallchain { 'baremetal:filter:IPv4':
  ensure => present,
} ->
firewall { '999 drop all baremetal':
  chain  => 'baremetal',
  action => 'drop',
  proto  => 'all',
} ->
firewall {'00 baremetal-filter':
  proto   => 'all',
  iniface => $baremetal_int,
  jump    => 'baremetal',
}

if member($roles, 'controller') or member($roles, 'primary-controller') {
  firewall { '100 allow baremetal ping from VIP':
    chain       => 'baremetal',
    source      => $baremetal_vip,
    destination => $baremetal_ipaddr,
    proto       => 'icmp',
    icmp        => 'echo-request',
    action      => 'accept',
  }
  firewall { '207 ironic-api' :
    dport   => '6385',
    proto   => 'tcp',
    action  => 'accept',
  }
}

if member($roles, 'ironic') {
  firewall { '101 allow baremetal-related':
    chain       => 'baremetal',
    source      => $baremetal_network,
    destination => $baremetal_ipaddr,
    proto       => 'all',
    state       => ['RELATED', 'ESTABLISHED'],
    action      => 'accept',
  }

  firewall { '102 allow baremetal-rsyslog':
    chain       => 'baremetal',
    source      => $baremetal_network,
    destination => $baremetal_ipaddr,
    proto       => 'udp',
    dport       => '514',
    action      => 'accept',
  }

  firewall { '103 allow baremetal-TFTP':
    chain       => 'baremetal',
    source      => $baremetal_network,
    destination => $baremetal_ipaddr,
    proto       => 'udp',
    dport       => '69',
    action      => 'accept',
  }

  k_mod {'nf_conntrack_tftp':
    ensure => 'present'
  }

  file_line {'nf_conntrack_tftp_on_boot':
    path => '/etc/modules',
    line => 'nf_conntrack_tftp',
  }
}
