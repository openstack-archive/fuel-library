notice('MODULAR: firewall.pp')

$network_scheme = hiera_hash('network_scheme')

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

prepare_network_config(hiera_hash('network_scheme'))
class { 'openstack::firewall' :
  nova_vnc_ip_range => get_routable_networks_for_network_role($network_scheme, 'nova/api'),
  libvirt_network   => get_network_role_property('management', 'network'),
  keystone_network  => get_network_role_property('keystone/api', 'network'),
}
