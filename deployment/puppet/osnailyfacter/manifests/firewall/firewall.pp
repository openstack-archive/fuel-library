class osnailyfacter::firewall::firewall {

  notice('MODULAR: firewall/firewall.pp')

  $network_scheme   = hiera_hash('network_scheme', {})
  $network_metadata = hiera_hash('network_metadata')
  $ironic_hash      = hiera_hash('ironic', {})
  $roles            = hiera('roles')
  $storage_hash     = hiera('storage', {})

  $aodh_port                    = 8042
  $ceilometer_port              = 8777
  $corosync_input_port          = 5404
  $corosync_output_port         = 5405
  $dhcp_server_port             = 67
  $dns_server_port              = 53
  $erlang_epmd_port             = 4369
  $erlang_inet_dist_port        = 41055
  $erlang_rabbitmq_backend_port = 5673
  $erlang_rabbitmq_port         = 5672
  $galera_clustercheck_port     = 49000
  $galera_ist_port              = 4568
  $galera_sst_port              = 4444
  $glance_api_port              = 9292
  $glance_glare_port            = 9494
  $glance_nova_api_ec2_port     = 8773
  $glance_reg_port              = 9191
  $heat_api_cfn_port            = 8000
  $heat_api_cloudwatch_port     = 8003
  $heat_api_port                = 8004
  $http_port                    = 80
  $https_port                   = 443
  $iscsi_port                   = 3260
  $keystone_admin_port          = 35357
  $keystone_public_port         = 5000
  $libvirt_migration_ports      = '49152-49215'
  $libvirt_port                 = 16509
  $memcached_port               = 11211
  $mongodb_port                 = 27017
  $murano_rabbitmq_port         = 55572
  $mysql_backend_port           = 3307
  $mysql_gcomm_port             = 4567
  $mysql_port                   = 3306
  $neutron_api_port             = 9696
  $nova_api_compute_port        = 8774
  $nova_api_metadata_port       = 8775
  $nova_api_vnc_ports           = '5900-6100'
  $nova_api_volume_port         = 8776
  $nova_vncproxy_port           = 6080
  $nrpe_server_port             = 5666
  $ntp_server_port              = 123
  $openvswitch_db_port          = 58882
  $pcsd_port                    = 2224
  $rsync_port                   = 873
  $ssh_port                     = 22
  $swift_account_port           = 6002
  $swift_container_port         = 6001
  $swift_object_port            = 6000
  $swift_proxy_check_port       = 49001
  $swift_proxy_port             = 8080
  $vxlan_udp_port               = 4789
  $ceph_mon_port                = 6789
  $ceph_osd_port                = '6800-7100'
  $radosgw_port                 = 6780

  $corosync_networks = get_routable_networks_for_network_role($network_scheme, 'mgmt/corosync')
  $memcache_networks = get_routable_networks_for_network_role($network_scheme, 'mgmt/memcache')
  $database_networks = get_routable_networks_for_network_role($network_scheme, 'mgmt/database')
  $keystone_networks = get_routable_networks_for_network_role($network_scheme, 'keystone/api')
  $nova_networks     = get_routable_networks_for_network_role($network_scheme, 'nova/api')
  $rabbitmq_networks = get_routable_networks_for_network_role($network_scheme, 'mgmt/messaging')
  $neutron_networks  = get_routable_networks_for_network_role($network_scheme, 'neutron/api')

  $admin_nets = get_routable_networks_for_network_role($network_scheme, 'admin/pxe')
  $management_nets = get_routable_networks_for_network_role($network_scheme, 'mgmt/vip')
  $storage_nets = unique(
    get_routable_networks_for_network_role($network_scheme, 'swift/replication'),
    get_routable_networks_for_network_role($network_scheme, 'ceph/replication')
  )

  # Ordering
  Class['::firewall'] -> Firewall<||>
  Class['::firewall'] -> Openstack::Firewall::Multi_net<||>
  Class['::firewall'] -> Firewallchain<||>

  class { '::firewall':}

  # Default rule for INPUT is DROP
  firewallchain { 'INPUT:filter:IPv4':
    policy => 'drop',
  }

  # Common rules
  firewall { '000 accept all icmp requests':
    proto  => 'icmp',
    action => 'accept',
  }

  firewall { '001 accept all to lo interface':
    proto   => 'all',
    iniface => 'lo',
    action  => 'accept',
  }

  firewall { '002 accept related established rules':
    proto  => 'all',
    state  => ['RELATED', 'ESTABLISHED'],
    action => 'accept',
  }

  openstack::firewall::multi_net {'020 ssh':
    port        => $ssh_port,
    proto       => 'tcp',
    action      => 'accept',
    source_nets => concat($admin_nets, $management_nets, $storage_nets),
  }

  openstack::firewall::multi_net {'109 iscsi':
    port        => $iscsi_port,
    proto       => 'tcp',
    action      => 'accept',
    source_nets => get_routable_networks_for_network_role($network_scheme, 'cinder/iscsi'),
  }

  openstack::firewall::multi_net {'112 ntp-server':
    port        => $ntp_server_port,
    proto       => 'udp',
    action      => 'accept',
    source_nets => $management_nets,
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
    dport  => $vxlan_udp_port,
    proto  => 'udp',
    action => 'accept',
  }

  # Role-related rules
  if member($roles, 'primary-controller') or member($roles, 'controller') {

    # Workaround for fuel bug with firewall
    firewall {'003 remote rabbitmq ':
      sport  => [ 4369, 5672, 41055, 55672, 61613 ],
      source => hiera('master_ip'),
      proto  => 'tcp',
      action => 'accept',
    }

    firewall {'004 remote puppet ':
      sport  => [ 8140 ],
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

    firewall { '100 http':
      dport  => [$http_port, $https_port],
      proto  => 'tcp',
      action => 'accept',
    }

    openstack::firewall::multi_net {'101 mysql':
      port        => [$mysql_port, $mysql_backend_port, $mysql_gcomm_port, $galera_ist_port, $galera_sst_port, $galera_clustercheck_port],
      proto       => 'tcp',
      action      => 'accept',
      source_nets => $database_networks,
    }

    openstack::firewall::multi_net {'102 keystone':
      port        => [$keystone_public_port, $keystone_admin_port],
      proto       => 'tcp',
      action      => 'accept',
      source_nets => $keystone_networks,
    }

    firewall {'103 swift':
      dport  => [$swift_proxy_port, $swift_object_port, $swift_container_port, $swift_account_port, $swift_proxy_check_port],
      proto  => 'tcp',
      action => 'accept',
    }

    firewall {'104 glance':
      dport  => [$glance_api_port, $glance_glare_port, $glance_reg_port, $glance_nova_api_ec2_port,],
      proto  => 'tcp',
      action => 'accept',
    }

    firewall {'105 nova':
      dport  => [$nova_api_compute_port, $nova_api_volume_port, $nova_vncproxy_port],
      proto  => 'tcp',
      action => 'accept',
    }

    openstack::firewall::multi_net {'105 nova internal - no ssl':
      port        => [$nova_api_metadata_port, $nova_api_vnc_ports],
      proto       => 'tcp',
      action      => 'accept',
      source_nets => $nova_networks,
    }

    openstack::firewall::multi_net {'106 rabbitmq':
      port        => [$erlang_epmd_port, $erlang_rabbitmq_port, $erlang_rabbitmq_backend_port, $erlang_inet_dist_port],
      proto       => 'tcp',
      action      => 'accept',
      source_nets => $rabbitmq_networks,
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

    openstack::firewall::multi_net {'108 rsync':
      port        => $rsync_port,
      proto       => 'tcp',
      action      => 'accept',
      source_nets => concat($management_nets, $storage_nets),
    }

    openstack::firewall::multi_net {'110 neutron':
      port        => $neutron_api_port,
      proto       => 'tcp',
      action      => 'accept',
      source_nets => $neutron_networks,
    }

    openstack::firewall::multi_net {'111 dns-server udp':
      port        => $dns_server_port,
      proto       => 'udp',
      action      => 'accept',
      source_nets => $management_nets,
    }

    openstack::firewall::multi_net {'111 dns-server tcp':
      port        => $dns_server_port,
      proto       => 'tcp',
      action      => 'accept',
      source_nets => $management_nets,
    }

    firewall {'111 dhcp-server':
      dport  => $dhcp_server_port,
      proto  => 'udp',
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

    openstack::firewall::multi_net {'116 openvswitch db':
      port        => $openvswitch_db_port,
      proto       => 'udp',
      action      => 'accept',
      source_nets => $management_nets,
    }

    firewall {'121 ceilometer':
      dport  => $ceilometer_port,
      proto  => 'tcp',
      action => 'accept',
    }

    firewall {'122 aodh':
      dport  => $aodh_port,
      proto  => 'tcp',
      action => 'accept',
    }

    firewall { '203 murano-rabbitmq' :
      dport  => $murano_rabbitmq_port,
      proto  => 'tcp',
      action => 'accept',
    }

    firewall {'204 heat-api':
      dport  => $heat_api_port,
      proto  => 'tcp',
      action => 'accept',
    }

    firewall {'205 heat-api-cfn':
      dport  => $heat_api_cfn_port,
      proto  => 'tcp',
      action => 'accept',
    }

    firewall {'206 heat-api-cloudwatch':
      dport  => $heat_api_cloudwatch_port,
      proto  => 'tcp',
      action => 'accept',
    }

  }

  if member($roles, 'compute') {

    openstack::firewall::multi_net {'105 nova vnc':
      port        => $nova_api_vnc_ports,
      proto       => 'tcp',
      action      => 'accept',
      source_nets => $nova_networks,
    }

    openstack::firewall::multi_net {'118 libvirt':
      port        => $libvirt_port,
      proto       => 'tcp',
      action      => 'accept',
      source_nets => $management_nets,
    }

    openstack::firewall::multi_net {'119 libvirt-migration':
      port        => $libvirt_migration_ports,
      proto       => 'tcp',
      action      => 'accept',
      source_nets => $management_nets,
    }
  }

  if member($roles, 'primary-mongo') or member($roles, 'mongo') {
    firewall {'120 mongodb':
      dport  => $mongodb_port,
      proto  => 'tcp',
      action => 'accept',
    }
  }

  if $ironic_hash['enabled'] {
    prepare_network_config($network_scheme)
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
        dport  => '6385',
        proto  => 'tcp',
        action => 'accept',
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

  if ($storage_hash['volumes_ceph'] or
      $storage_hash['images_ceph'] or
      $storage_hash['objects_ceph'] or
      $storage_hash['ephemeral_ceph']
  ) {
    if member($roles, 'primary-controller') or member($roles, 'controller') {
      firewall {'010 ceph-mon allow':
        chain  => 'INPUT',
        dport  => $ceph_mon_port,
        proto  => 'tcp',
        action => accept,
      }
    }

    if member($roles, 'ceph-osd') {
      firewall { '011 ceph-osd allow':
        chain  => 'INPUT',
        dport  => $ceph_osd_port,
        proto  => 'tcp',
        action => accept,
      }
    }

    if $storage_hash['objects_ceph'] {
      if member($roles, 'primary-controller') or member($roles, 'controller') {
        firewall {'012 RadosGW allow':
          chain   => 'INPUT',
          dport   => [ $radosgw_port, $swift_proxy_port ],
          proto   => 'tcp',
          action  => accept,
        }
      }
    }
  }

}
