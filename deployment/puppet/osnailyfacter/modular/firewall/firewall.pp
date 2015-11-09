notice('MODULAR: firewall.pp')

$network_scheme = hiera_hash('network_scheme')
$ironic_hash = hiera_hash('ironic', {})

# Workaround for fuel bug with firewall
firewall {'003 remote rabbitmq ':
  sport   => [ 4369, 5672, 41055, 55672, 61613 ],
  source  => hiera('master_ip'),
  proto   => 'tcp',
  action  => 'accept',
  require => Class['openstack::firewall'],
}

firewall {'004 remote puppet ':
  sport   => [ 8140 ],
  source  => hiera('master_ip'),
  proto   => 'tcp',
  action  => 'accept',
  require => Class['openstack::firewall'],
}

# allow local rabbitmq admin traffic for LP#1383258
firewall {'005 local rabbitmq admin':
  sport   => [ 15672 ],
  iniface => 'lo',
  proto   => 'tcp',
  action  => 'accept',
  require => Class['openstack::firewall'],
}

# reject all non-local rabbitmq admin traffic for LP#1450443
firewall {'006 reject non-local rabbitmq admin':
  sport   => [ 15672 ],
  proto   => 'tcp',
  action  => 'drop',
  require => Class['openstack::firewall'],
}

# allow connections from haproxy namespace
firewall {'030 allow connections from haproxy namespace':
  source  => '240.0.0.2',
  action  => 'accept',
  require => Class['openstack::firewall'],
}

prepare_network_config(hiera_hash('network_scheme'))
class { 'openstack::firewall' :
  nova_vnc_ip_range => get_routable_networks_for_network_role($network_scheme, 'nova/api'),
  nova_api_ip_range => get_network_role_property('nova/api', 'network'),
  libvirt_network   => get_network_role_property('management', 'network'),
  keystone_network  => get_network_role_property('keystone/api', 'network'),
  iscsi_ip          => get_network_role_property('cinder/iscsi', 'ipaddr'),
}

if $ironic_hash['enabled'] {
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
    require => Class['openstack::firewall'],
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
}
