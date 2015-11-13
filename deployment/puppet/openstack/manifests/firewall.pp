# == Class: openstack::firewall
#
# This class creates firewall rules that apply to any OpenStack node.
#
# === Parameters
#  [*admin_nets*]
#    Array. List of networks in CIDR notation for Admin nets.
#    Default value is ['0.0.0.0/0'],
#
#  [*public_nets*]
#    Array. List of networks in CIDR notation for Public nets.
#    Default value is ['0.0.0.0/0'],
#
#  [*management_nets*]
#    Array. List of networks in CIDR notation for Management nets.
#    Default value is ['0.0.0.0/0'],
#
#  [*storage_nets*]
#    Array. List of networks in CIDR notation for Storage nets.
#    Default value is ['0.0.0.0/0'],
#
#  [*keystone_network*]
#    String. Network for for keystone public API
#    Default value is '0.0.0.0/0',
#
#  [*ceilometer_port*]
#    String. Port for ceilometer
#    Default value is 8777,
#
#  [*corosync_input_port*]
#    String. Port for corosync_input
#    Default value is 5404,
#
#  [*corosync_output_port*]
#    String. Port for corosync_output
#    Default value is 5405,
#
#  [*dhcp_server_port*]
#    String. Port for dhcp_server
#    Default value is 67,
#
#  [*dns_server_port*]
#    String. Port for dns_server
#    Default value is 53,
#
#  [*erlang_epmd_port*]
#    String. Port for erlang_epmd
#    Default value is 4369,
#
#  [*erlang_inet_dist_port*]
#    String. Port for erlang_inet_dist
#    Default value is 41055,
#
#  [*erlang_rabbitmq_backend_port*]
#    String. Port for erlang_rabbitmq_backend
#    Default value is 5673,
#
#  [*erlang_rabbitmq_port*]
#    String. Port for erlang_rabbitmq
#    Default value is 5672,
#
#  [*galera_clustercheck_port*]
#    String. Port for galera_clustercheck
#    Default value is 49000,
#
#  [*galera_ist_port*]
#    String. Port for galera_ist
#    Default value is 4568,
#
#  [*glance_api_port*]
#    String. Port for glance_api
#    Default value is 9292,
#
#  [*glance_nova_api_ec2_port*]
#    String. Port for glance_nova_api_ec2
#    Default value is 8773,
#
#  [*glance_reg_port*]
#    String. Port for glance_reg
#    Default value is 9191,
#
#  [*heat_api_cfn_port*]
#    String. Port for heat_api_cfn
#    Default value is 8000,
#
#  [*heat_api_cloudwatch_port*]
#    String. Port for heat_api_cloudwatch
#    Default value is 8003,
#
#  [*heat_api_port*]
#    String. Port for heat_api
#    Default value is 8004,
#
#  [*http_port*]
#    String. Port for http
#    Default value is 80,
#
#  [*https_port*]
#    String. Port for https
#    Default value is 443,
#
#  [*iscsi_port*]
#    String. Port for iscsi
#    Default value is 3260,
#
#  [*keystone_admin_port*]
#    String. Port for keystone_admin
#    Default value is 35357,
#
#  [*keystone_public_port*]
#    String. Port for keystone_public
#    Default value is 5000,
#
#  [*libvirt_migration_ports*]
#    String. Port for libvirt_migration_ports
#    Default value is '49152-49215',
#
#  [*libvirt_port*]
#    String. Port for libvirt
#    Default value is 16509,
#
#  [*memcached_port*]
#    String. Port for memcached
#    Default value is 11211,
#
#  [*mongodb_port*]
#    String. Port for mongodb
#    Default value is 27017,
#
#  [*mysql_backend_port*]
#    String. Port for mysql_backend
#    Default value is 3307,
#
#  [*mysql_gcomm_port*]
#    String. Port for mysql_gcomm
#    Default value is 4567,
#
#  [*mysql_port*]
#    String. Port for mysql
#    Default value is 3306,
#
#  [*neutron_api_port*]
#    String. Port for neutron_api
#    Default value is 9696,
#
#  [*nova_api_compute_port*]
#    String. Port for nova_api_compute
#    Default value is 8774,
#
#  [*nova_api_metadata_port*]
#    String. Port for nova_api_metadata
#    Default value is 8775,
#
#  [*nova_api_vnc_ports*]
#    String. Port for nova_api_vnc_ports
#    Default value is '5900-6100',
#
#  [*nova_api_volume_port*]
#    String. Port for nova_api_volume
#    Default value is 8776,
#
#  [*nova_vncproxy_port*]
#    String. Port for nova_vncproxy
#    Default value is 6080,
#
#  [*nrpe_server_port*]
#    String. Port for nrpe_server
#    Default value is 5666,
#
#  [*ntp_server_port*]
#    String. Port for ntp_server
#    Default value is 123,
#
#  [*openvswitch_db_port*]
#    String. Port for openvswitch_db
#    Default value is 58882,
#
#  [*pcsd_port*]
#    String. Port for pcsd
#    Default value is 2224,
#
#  [*rsync_port*]
#    String. Port for rsync
#    Default value is 873,
#
#  [*ssh_port*]
#    String. Port for ssh
#    Default value is 22,
#
#  [*swift_account_port*]
#    String. Port for swift_account
#    Default value is 6002,
#
#  [*swift_container_port*]
#    String. Port for swift_container
#    Default value is 6001,
#
#  [*swift_object_port*]
#    String. Port for swift_object
#    Default value is 6000,
#
#  [*swift_proxy_check_port*]
#    String. Port for swift_proxy_check
#    Default value is 49001,
#
#  [*swift_proxy_port*]
#    String. Port for swift_proxy
#    Default value is 8080,
#
#  [*vxlan_udp_port*]
#    String. Port for vxlan_udp
#    Default value is 4789,
#

class openstack::firewall (
  $admin_nets                   = ['0.0.0.0/0'],
  $public_nets                  = ['0.0.0.0/0'],
  $management_nets              = ['0.0.0.0/0'],
  $storage_nets                 = ['0.0.0.0/0'],

  $keystone_network             = '0.0.0.0/0',

  $ceilometer_port              = 8777,
  $corosync_input_port          = 5404,
  $corosync_output_port         = 5405,
  $dhcp_server_port             = 67,
  $dns_server_port              = 53,
  $erlang_epmd_port             = 4369,
  $erlang_inet_dist_port        = 41055,
  $erlang_rabbitmq_backend_port = 5673,
  $erlang_rabbitmq_port         = 5672,
  $galera_clustercheck_port     = 49000,
  $galera_ist_port              = 4568,
  $glance_api_port              = 9292,
  $glance_nova_api_ec2_port     = 8773,
  $glance_reg_port              = 9191,
  $heat_api_cfn_port            = 8000,
  $heat_api_cloudwatch_port     = 8003,
  $heat_api_port                = 8004,
  $http_port                    = 80,
  $https_port                   = 443,
  $iscsi_port                   = 3260,
  $keystone_admin_port          = 35357,
  $keystone_public_port         = 5000,
  $libvirt_migration_ports      = '49152-49215',
  $libvirt_port                 = 16509,
  $memcached_port               = 11211,
  $mongodb_port                 = 27017,
  $mysql_backend_port           = 3307,
  $mysql_gcomm_port             = 4567,
  $mysql_port                   = 3306,
  $neutron_api_port             = 9696,
  $nova_api_compute_port        = 8774,
  $nova_api_metadata_port       = 8775,
  $nova_api_vnc_ports           = '5900-6100',
  $nova_api_volume_port         = 8776,
  $nova_vncproxy_port           = 6080,
  $nrpe_server_port             = 5666,
  $ntp_server_port              = 123,
  $openvswitch_db_port          = 58882,
  $pcsd_port                    = 2224,
  $rsync_port                   = 873,
  $ssh_port                     = 22,
  $swift_account_port           = 6002,
  $swift_container_port         = 6001,
  $swift_object_port            = 6000,
  $swift_proxy_check_port       = 49001,
  $swift_proxy_port             = 8080,
  $vxlan_udp_port               = 4789,
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
    source_nets => concat($admin_nets, $management_nets, $storage_nets),
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
    source_nets => $management_nets,
  }

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

  openstack::firewall::multi_net {'105 nova internal - no ssl':
    port        => [$nova_api_metadata_port, $nova_api_vnc_ports],
    proto       => 'tcp',
    action      => 'accept',
    source_nets => $management_nets,
  }

  openstack::firewall::multi_net {'106 rabbitmq':
    port        => [$erlang_epmd_port, $erlang_rabbitmq_port,
                    $erlang_rabbitmq_backend_port, $erlang_inet_dist_port],
    proto       => 'tcp',
    action      => 'accept',
    source_nets => $management_nets,
  }

  openstack::firewall::multi_net {'107 memcache tcp':
    port        => $memcached_port,
    proto       => 'tcp',
    action      => 'accept',
    source_nets => $management_nets,
  }

  openstack::firewall::multi_net {'107 memcache udp':
    port        => $memcached_port,
    proto       => 'udp',
    action      => 'accept',
    source_nets => $management_nets,
  }

  openstack::firewall::multi_net {'108 rsync':
    port        => $rsync_port,
    proto       => 'tcp',
    action      => 'accept',
    source_nets => concat($management_nets, $storage_nets),
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
    source_nets => $management_nets,
  }

  openstack::firewall::multi_net {'111 dns-server tcp':
    port        => $dns_server_port,
    proto       => 'tcp',
    action      => 'accept',
    source_nets => $management_nets,
  }

  firewall {'111 dhcp-server':
    port   => $dhcp_server_port,
    proto  => 'udp',
    action => 'accept',
  }

  openstack::firewall::multi_net {'112 ntp-server':
    port        => $ntp_server_port,
    proto       => 'udp',
    action      => 'accept',
    source_nets => $management_nets,
  }

  openstack::firewall::multi_net {'113 corosync-input':
    port        => $corosync_input_port,
    proto       => 'udp',
    action      => 'accept',
    source_nets => $management_nets,
  }

  openstack::firewall::multi_net {'114 corosync-output':
    port        => $corosync_output_port,
    proto       => 'udp',
    action      => 'accept',
    source_nets => $management_nets,
  }

  openstack::firewall::multi_net {'115 pcsd-server':
    port        => $pcsd_port,
    proto       => 'tcp',
    action      => 'accept',
    source_nets => $management_nets,
  }

  openstack::firewall::multi_net {'116 openvswitch db':
    port        => $openvswitch_db_port,
    proto       => 'udp',
    action      => 'accept',
    source_nets => $management_nets,
  }

  openstack::firewall::multi_net {'117 nrpe-server':
    port        => $nrpe_server_port,
    proto       => 'udp',
    action      => 'accept',
    source_nets => concat($admin_nets, $management_nets),
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
