notice('MODULAR: database/database_firewall.pp')

$network_scheme   = hiera_hash('network_scheme')
$network_metadata = hiera_hash('network_metadata')

$corosync_input_port          = 5404
$corosync_output_port         = 5405
$galera_clustercheck_port     = 49000
$galera_ist_port              = 4568
$galera_sst_port              = 4444
$mysql_backend_port           = 3307
$mysql_gcomm_port             = 4567
$mysql_port                   = 3306
$pcsd_port                    = 2224


$corosync_networks = get_routable_networks_for_network_role($network_scheme, 'mgmt/corosync')
$database_networks = get_routable_networks_for_network_role($network_scheme, 'mgmt/database')

# allow connections from haproxy namespace
firewall {'030 allow connections from haproxy namespace':
  source => '240.0.0.2',
  action => 'accept',
}

openstack::firewall::multi_net {'101 mysql':
  port        => [$mysql_port, $mysql_backend_port, $mysql_gcomm_port,
                  $galera_ist_port, $galera_sst_port,
                  $galera_clustercheck_port],
  proto       => 'tcp',
  action      => 'accept',
  source_nets => $database_networks,
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
