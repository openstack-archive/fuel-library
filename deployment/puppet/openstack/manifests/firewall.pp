#FIXME(mattymo): docstrings and sort parameters
class openstack::firewall (
  $admin_nets                   = ['0.0.0.0/0'],
  $public_nets                  = ['0.0.0.0/0'],
  $private_nets                 = ['0.0.0.0/0'],
  $storage_nets                 = ['0.0.0.0/0'],
  $ssh_port                     = 22,
  $http_port                    = 80,
  $https_port                   = 443,
  $mysql_port                   = 3306,
  $mysql_backend_port           = 3307,
  $mysql_gcomm_port             = 4567,
  $galera_ist_port              = 4568,
  $galera_clustercheck_port     = 49000,
  $swift_proxy_check_port       = 49001,
  $keystone_public_port         = 5000,
  $swift_proxy_port             = 8080,
  $swift_object_port            = 6000,
  $swift_container_port         = 6001,
  $swift_account_port           = 6002,
  $keystone_admin_port          = 35357,
  $glance_api_port              = 9292,
  $glance_reg_port              = 9191,
  $glance_nova_api_ec2_port     = 8773,
  $nova_api_compute_port        = 8774,
  $nova_api_metadata_port       = 8775,
  $nova_api_volume_port         = 8776,
  $nova_api_vnc_ports           = '5900-6100',
  $nova_vncproxy_port           = 6080,
  $erlang_epmd_port             = 4369,
  $erlang_rabbitmq_port         = 5672,
  $erlang_rabbitmq_backend_port = 5673,
  $erlang_inet_dist_port        = 41055,
  $memcached_port               = 11211,
  $rsync_port                   = 873,
  $iscsi_port                   = 3260,
  $neutron_api_port             = 9696,
  $dns_server_port              = 53,
  $dhcp_server_port             = 67,
  $ntp_server_port              = 123,
  $corosync_input_port          = 5404,
  $corosync_output_port         = 5405,
  $pcsd_port                    = 2224,
  $openvswitch_db_port          = 58882,
  $libvirt_port                 = 16509,
  $libvirt_migration_ports      = '49152-49215',
  $nrpe_server_port             = 5666,
  $ceilometer_port              = 8777,
  $heat_api_port                = 8004,
  $heat_api_cfn_port            = 8000,
  $heat_api_cloudwatch_port     = 8003,
  $mongodb_port                 = 27017,
  $vxlan_udp_port               = 4789,
  $keystone_network             = '0.0.0.0/0',
) {

  class {'::firewall':}

  firewall { '000 accept all icmp requests':
    proto  => 'icmp',
    action => 'accept',
  }->

  firewall { '001 accept all to lo interface':
    proto   => 'all',
    iniface => 'lo',
    action  => 'accept',
  }->

  firewall { '002 accept related established rules':
    proto  => 'all',
    state  => ['RELATED', 'ESTABLISHED'],
    action => 'accept',
  }

  openstack::firewall::multi_net {'020 ssh':
    port        => $ssh_port,
    proto       => 'tcp',
    action      => 'accept',
    source_nets => concat($admin_nets, $private_nets, $storage_nets),
  }

  firewall { '100 http':
    port   => [$http_port, $https_port],
    proto  => 'tcp',
    action => 'accept',
  }

  openstack::firewall::multi_net {'101 mysql':
    port        => [$mysql_port, $mysql_backend_port, $mysql_gcomm_port,
      $galera_ist_port, $galera_clustercheck_port],
    proto       => 'tcp',
    action      => 'accept',
    source_nets => $private_nets,
  }

  #FIXME(mattmyo): currently public traffic is blocked, but other APIs are open
  # We should address this ASAP.
  firewall {'102 keystone':
    port        => [$keystone_public_port,$keystone_admin_port],
    proto       => 'tcp',
    action      => 'accept',
    destination => $keystone_network,
  }

  firewall {'103 swift':
    port   => [$swift_proxy_port, $swift_object_port, $swift_container_port,
                $swift_account_port, $swift_proxy_check_port],
    proto  => 'tcp',
    action => 'accept',
  }

  firewall {'104 glance':
    port   => [$glance_api_port, $glance_reg_port, $glance_nova_api_ec2_port,],
    proto  => 'tcp',
    action => 'accept',
  }

  firewall {'105 nova':
    port   => [$nova_api_compute_port,$nova_api_volume_port,
      $nova_vncproxy_port],
    proto  => 'tcp',
    action => 'accept',
  }

  openstack::firewall::multi_net {'105 nova private - no ssl':
    port        => [$nova_api_metadata_port, $nova_api_vnc_ports],
    proto       => 'tcp',
    action      => 'accept',
    source_nets => $private_nets,
  }

  openstack::firewall::multi_net {'106 rabbitmq':
    port        => [$erlang_epmd_port, $erlang_rabbitmq_port,
                    $erlang_rabbitmq_backend_port, $erlang_inet_dist_port],
    proto       => 'tcp',
    action      => 'accept',
    source_nets => $private_nets,
  }

  openstack::firewall::multi_net {'107 memcache tcp':
    port        => $memcached_port,
    proto       => 'tcp',
    action      => 'accept',
    source_nets => $private_nets,
  }

  openstack::firewall::multi_net {'107 memcache udp':
    port        => $memcached_port,
    proto       => 'udp',
    action      => 'accept',
    source_nets => $private_nets,
  }

  openstack::firewall::multi_net {'108 rsync':
    port        => $rsync_port,
    proto       => 'tcp',
    action      => 'accept',
    source_nets => concat($private_nets, $storage_nets),
  }

  openstack::firewall::multi_net {'109 iscsi':
    port        => $iscsi_port,
    proto       => 'tcp',
    action      => 'accept',
    source_nets => $storage_nets,
  }

  firewall {'110 neutron':
    port   => $neutron_api_port,
    proto  => 'tcp',
    action => 'accept',
  }

  openstack::firewall::multi_net {'111 dns-server udp':
    port        => $dns_server_port,
    proto       => 'udp',
    action      => 'accept',
    source_nets => $private_nets,
  }

  openstack::firewall::multi_net {'111 dns-server tcp':
    port        => $dns_server_port,
    proto       => 'tcp',
    action      => 'accept',
    source_nets => $private_nets,
  }

  #FIXME(mattymo): Maybe we don't need this rule
  firewall {'111 dhcp-server':
    port   => $dhcp_server_port,
    proto  => 'udp',
    action => 'accept',
  }

  openstack::firewall::multi_net {'112 ntp-server':
    port        => $ntp_server_port,
    proto       => 'udp',
    action      => 'accept',
    source_nets => $private_nets,
  }

  openstack::firewall::multi_net {'113 corosync-input':
    port        => $corosync_input_port,
    proto       => 'udp',
    action      => 'accept',
    source_nets => $private_nets,
  }

  openstack::firewall::multi_net {'114 corosync-output':
    port        => $corosync_output_port,
    proto       => 'udp',
    action      => 'accept',
    source_nets => $private_nets,
  }

  openstack::firewall::multi_net {'115 pcsd-server':
    port        => $pcsd_port,
    proto       => 'tcp',
    action      => 'accept',
    source_nets => $private_nets,
  }

  openstack::firewall::multi_net {'116 openvswitch db':
    port        => $openvswitch_db_port,
    proto       => 'udp',
    action      => 'accept',
    source_nets => $private_nets,
  }

  openstack::firewall::multi_net {'117 nrpe-server':
    port        => $nrpe_server_port,
    proto       => 'udp',
    action      => 'accept',
    source_nets => concat($admin_nets, $private_nets),
  }

  openstack::firewall::multi_net {'118 libvirt':
    port        => $libvirt_port,
    proto       => 'tcp',
    action      => 'accept',
    source_nets => $private_nets,
  }

  openstack::firewall::multi_net {'119 libvirt-migration':
    port        => $libvirt_migration_ports,
    proto       => 'tcp',
    action      => 'accept',
    source_nets => $private_nets,
  }

  firewall {'121 ceilometer':
    port   => $ceilometer_port,
    proto  => 'tcp',
    action => 'accept',
  }

  firewall {'204 heat-api':
    port   => $heat_api_port,
    proto  => 'tcp',
    action => 'accept',
  }

  firewall {'205 heat-api-cfn':
    port   => $heat_api_cfn_port,
    proto  => 'tcp',
    action => 'accept',
  }

  firewall {'206 heat-api-cloudwatch':
    port   => $heat_api_cloudwatch_port,
    proto  => 'tcp',
    action => 'accept',
  }

  firewall { '333 notrack gre':
    chain => 'PREROUTING',
    table => 'raw',
    proto => 'gre',
    jump  => 'NOTRACK',
  }

  firewall { '334 accept gre':
    chain  => 'INPUT',
    table  => 'filter',
    proto  => 'gre',
    action => 'accept',
  }

  firewall {'340 vxlan_udp_port':
    port   => $vxlan_udp_port,
    proto  => 'udp',
    action => 'accept',
  }

  firewall { '999 drop all other requests':
    proto  => 'all',
    chain  => 'INPUT',
    action => 'drop',
  }


}
