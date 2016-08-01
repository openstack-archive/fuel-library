notice('MODULAR: detach-keystone/keystone_firewall.pp')

$network_scheme   = hiera_hash('network_scheme')
$network_metadata = hiera_hash('network_metadata')

$corosync_input_port          = 5404
$corosync_output_port         = 5405
$keystone_admin_port          = 35357
$keystone_public_port         = 5000
$memcached_port               = 11211
$pcsd_port                    = 2224

$corosync_networks = get_routable_networks_for_network_role($network_scheme, 'mgmt/corosync')
$memcache_networks = get_routable_networks_for_network_role($network_scheme, 'mgmt/memcache')
$keystone_networks = get_routable_networks_for_network_role($network_scheme, 'keystone/api')

# allow connections from haproxy namespace
firewall {'030 allow connections from haproxy namespace':
  source => '240.0.0.2',
  action => 'accept',
}

openstack::firewall::multi_net {'102 keystone':
  port        => [$keystone_public_port, $keystone_admin_port],
  proto       => 'tcp',
  action      => 'accept',
  source_nets => $keystone_networks,
}

openstack::firewall::multi_net {'107 memcache tcp':
  port        => $memcached_port,
  proto       => 'tcp',
  action      => 'accept',
  source_nets => $memcache_networks,
}

openstack::firewall::multi_net {'107 memcache udp':
  port        => $memcached_port,
  proto       => 'udp',
  action      => 'accept',
  source_nets => $memcache_networks,
}

openstack::firewall::multi_net {'113 corosync-input':
  port        => $corosync_input_port,
  proto       => 'udp',
  action      => 'accept',
  source_nets => $corosync_networks,
}

openstack::firewall::multi_net {'114 corosync-output':
  port        => $corosync_output_port,
  proto       => 'udp',
  action      => 'accept',
  source_nets => $corosync_networks,
}

openstack::firewall::multi_net {'115 pcsd-server':
  port        => $pcsd_port,
  proto       => 'tcp',
  action      => 'accept',
  source_nets => $corosync_networks,
}
