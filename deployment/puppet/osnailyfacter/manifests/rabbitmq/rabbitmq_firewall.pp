notice('MODULAR: rabbitmq/rabbitmq_firewall.pp')

$network_scheme   = hiera_hash('network_scheme')
$network_metadata = hiera_hash('network_metadata')

$corosync_input_port          = 5404
$corosync_output_port         = 5405
$erlang_epmd_port             = 4369
$erlang_inet_dist_port        = 41055
$erlang_rabbitmq_backend_port = 5673
$erlang_rabbitmq_port         = 5672
$pcsd_port                    = 2224

$corosync_networks = get_routable_networks_for_network_role($network_scheme, 'mgmt/corosync')
$rabbitmq_networks = get_routable_networks_for_network_role($network_scheme, 'mgmt/messaging')


openstack::firewall::multi_net {'106 rabbitmq':
  port        => [$erlang_epmd_port, $erlang_rabbitmq_port, $erlang_rabbitmq_backend_port, $erlang_inet_dist_port],
  proto       => 'tcp',
  action      => 'accept',
  source_nets => $rabbitmq_networks,
}

# Workaround for fuel bug with firewall
firewall {'003 remote rabbitmq ':
  sport  => [ 4369, 5672, 41055, 55672, 61613 ],
  source => hiera('master_ip'),
  proto  => 'tcp',
  action => 'accept',
}

# allow local rabbitmq admin traffic for LP#1383258
firewall {'005 local rabbitmq admin':
  sport   => [ 15672 ],
  iniface => 'lo',
  proto   => 'tcp',
  action  => 'accept',
}

# reject all non-local rabbitmq admin traffic for LP#1450443
firewall {'006 reject non-local rabbitmq admin':
  sport  => [ 15672 ],
  proto  => 'tcp',
  action => 'drop',
}

# allow connections from haproxy namespace
firewall {'030 allow connections from haproxy namespace':
  source => '240.0.0.2',
  action => 'accept',
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

